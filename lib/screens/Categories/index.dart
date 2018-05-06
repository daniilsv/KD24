import 'dart:async';

import 'package:fluro/fluro.dart';
import "package:flutter/material.dart";
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/components/Search/searchBar.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';
import 'package:shop_spy/services/send_data.dart';
import 'package:shop_spy/services/utils.dart';

class ScreenCategories extends StatefulWidget {
  ScreenCategories({Key key, this.shopId}) : super(key: key);

  final int shopId;

  @override
  ScreenCategoriesState createState() => new ScreenCategoriesState();
}

class ScreenCategoriesState extends State<ScreenCategories> {
  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(value)));
  }

  Shop shop = new Shop();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var _items = [];

  getCategories() async {
    if (_items.length == 0) {
      _items = await _loadCategoriesFromDatabase();
      if (_items.length == 0) {
        bool status = await _handleRefresh<bool>();
        if (status) _items = await _loadCategoriesFromDatabase();
      }
    }
    setState(() {});
  }

  Future<List> _loadCategoriesFromDatabase() async {
    var db = new DataBase();
    List<String> _categories = await db
        .selectOnly("p.category")
        .joinLeft("products", "p", "p.id=i.product_id")
        .filterEqual("shop_id", widget.shopId)
        .orderBy("p.category")
        .groupBy("p.category")
        .get<String>("shop_products", callback: (var row) => row['category']);

    return _categories;
  }

  SearchBar searchBar;

  AppBar buildAppBar(BuildContext context) {
    Widget title = const Text("");
    if (shop != null) title = new Text(shop.name, style: new TextStyle(color: Colors.white));
    return new AppBar(
      title: title,
      backgroundColor: Colors.orange,
      actions: [searchBar.getSearchAction(context)],
      centerTitle: true,
    );
  }

  @override
  void initState() {
    super.initState();
    getAppBarTitle();
    searchBar = new SearchBar(
        inBar: true,
        setState: setState,
        onType: onSearchType,
        onSubmitted: onSearchType,
        onClear: onSearchClear,
        buildDefaultAppBar: buildAppBar,
        needBarCodeCamera: true);
    getCategories();
  }

  String searchPhrase;

  void onSearchType(String value) {
    searchPhrase = value;
    getProducts();
  }

  void onSearchClear() {
    searchPhrase = "";
    getProducts();
  }

  var items = [];

  getProducts() async {
    List<Product> _items = [];
    var db = new DataBase();
    db
        .select("p.*")
        .joinLeft("products", "p", "p.id=i.product_id")
        .filterEqual("i.shop_id", widget.shopId)
        .orderBy("p.name");

    if (!Config.moveDownDone) {
      List<Product> rows = await db.get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);
    } else {
      List<Product> rows = await db
          .filterIsNull("price_new")
          .get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);

      rows = await db
          .select("p.*")
          .joinLeft("products", "p", "p.id=i.product_id")
          .filterEqual("i.shop_id", widget.shopId)
          .orderBy("p.name")
          .filterNotNull("price_new")
          .get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);
    }
    items = [];
    if (searchPhrase != null && searchPhrase.length > 0) {
      for (var product in _items) {
        var a = Utils.compResult(product.name, searchPhrase);
        var b = Utils.compResult(product.barcode, searchPhrase);
        product.order = a > b ? a : b;
        if (product.order > 10) items.add(product);
      }
      items.sort((a, b) => a.order > b.order ? -1 : a.order < b.order ? 1 : 0);
    } else
      items = _items;
    setState(() {});
  }

  Future<T> _handleRefresh<T>([bool tIsNull = false]) async {
    var data = await HttpQuery
        .executeJsonQuery("Products/GetTodayCheckProduct", params: {"retailerId": widget.shopId.toString()});

    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
      if (tIsNull)
        return null;
      else
        return false as T;
    }

    if ((data as List).length == 0) {
      if (tIsNull)
        return null;
      else
        return false as T;
    }

    List<Map<String, dynamic>> _products = [];
    List<Map<String, dynamic>> _shopPrice = [];
    for (Map<String, dynamic> product in data) {
      _products.add({
        "id": product['id'],
        "category": product['category'],
        "name": product['name'],
        "brand": product['brand'],
        "barcode": product['barCode'],
        "volume": product['volume'],
        "volume_value": product['volumeValue'],
        "image": product['image']
      });

      _shopPrice.add({
        "product_id": product['id'],
        "shop_id": widget.shopId,
        "price": (product['lastPriceThisRetailer'] as String).length > 2
            ? double.parse(product['lastPriceThisRetailer'])
            : 0.0,
        "date": (product['lastPriceThisRetailerDate'] as String).length > 2 ? product['lastPriceThisRetailerDate'] : 0.0
      });
      _shopPrice.add({
        "product_id": product['id'],
        "shop_id": product['minPriceRetailerId'],
        "price": (product['minPrice'] as String).length > 2 ? product['minPrice'] : 0.0
      });
    }

    var db = new DataBase();
    await db.insertList("products", _products);
    await db.insertList("shop_products", _shopPrice);
    if (tIsNull)
      return null;
    else
      return true as T;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  getAppBarTitle() async {
    var db = new DataBase();
    shop = await db.getItemById("shops", widget.shopId, callback: (Map shop) => new Shop.fromJson(shop));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget list = new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        return new Row(children: [
          new Expanded(
              child: new Card(
                child: new MaterialButton(
                  height: 50.0,
                  child: new ListTile(
                    title: new Text(
                      _items[index],
                      style: new TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onPressed: () =>
                      Routes.navigateTo(
                          context,
                          "/shop/${widget.shopId}/"
                              "${_items[index]}"),
                ),
              ))
        ]);
      },
    );
    if (searchPhrase != null && searchPhrase.length != 0)
      list = new ListView.builder(
        padding: kMaterialListPadding,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          Product product = items[index];
          return new Row(children: [
            new Expanded(
                child: new Card(
                  child: new MaterialButton(
                      child: new Column(children: <Widget>[
                        new ListTile(
                          title: new Text(product.name),
                          subtitle: new Text(product.barcode, style: new TextStyle(fontSize: 16.0)),
                          leading: new Image(
                            image: new AdvancedNetworkImage(
                                HttpQuery.hrefTo("prodbasecontent/Images",
                                    baseUrl: "prodbasestorage.blob.core.windows.net", file: product.image),
                                useDiskCache: true),
                            fit: BoxFit.contain,
                            height: 80.0,
                            width: 40.0,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        new Row(
                          children: <Widget>[
                            product.price != null
                                ? new Text(product.price.toString() ?? "", style: new TextStyle(color: Colors.grey))
                                : const Text(""),
                            product.price != null ? new Icon(FontAwesomeIcons.arrowRight, size: 12.0) : const Text(""),
                            product.priceNew == null
                                ? const Icon(FontAwesomeIcons.times, color: Colors.red)
                                : new Text(
                                product.priceNew.toString() ?? "", style: new TextStyle(color: Colors.green)),
                            new Padding(
                                padding: new EdgeInsets.only(left: 10.0),
                                child: new Text("за ${product.volumeValue} ${product.volumeText}")),
                            product.priceNew != null && product.isSaleNew
                                ? const Icon(FontAwesomeIcons.star)
                                : const Text(""),
                          ],
                        ),
                        new Padding(
                          padding: new EdgeInsets.only(top: 5.0),
                        )
                      ]),
                      onPressed: () => openProduct("/product/${widget.shopId}/${product.id}", index)),
                ))
          ]);
        },
      );
    return new Scaffold(
      key: _scaffoldKey,
      drawer: new DrawerMain(
        sendWidget: new ListTile(
          leading: const Icon(FontAwesomeIcons.telegramPlane),
          title: new Text('Отправить изменения'),
          onTap: () => openSendModal(),
        ),
        settingsWidget: new ListTile(
          leading: const Icon(FontAwesomeIcons.slidersH),
          title: new Text('Настройки'),
          onTap: () => openSettings(),
        ),
      ),
      appBar: searchBar.build(context),
      floatingActionButton: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new FloatingActionButton(
              heroTag: "0", child: const Icon(FontAwesomeIcons.plus), onPressed: () => openProductAdd()),
          new Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: new FloatingActionButton(
                heroTag: "1", child: const Icon(FontAwesomeIcons.barcode), onPressed: () => openBarcodeSearch()),
          ),
        ],
      ),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _handleRefresh<Null>(true),
        child: list,
      ),
    );
  }

  openProductAdd() async {
    if (Utils.calcEpCode(searchPhrase)) {
      var db = new DataBase();
      Product prod = await db
          .filterEqual("barcode", searchPhrase)
          .getItem<Product>("products", callback: (Map item) => new Product.fromJson(item));
      if (prod != null) {
        await db.updateOrInsert("shop_products", {"product_id": prod.id, "shop_id": widget.shopId});
        openProduct("/product/${widget.shopId}/${prod.id}", -1);
        return;
      }
      var res = await HttpQuery.executeJsonQuery("Products/GetProductCheck", params: {"barCode": searchPhrase});
      if (res is Map) {
        await db.updateOrInsert("products", {
          "id": res['id'],
          "category": res['category'],
          "name": res['name'],
          "brand": res['brand'],
          "barcode": res['barCode'],
          "volume": res['volume'],
          "volume_value": res['volumeValue'],
          "image": res['image']
        });
        await db.updateOrInsert("shop_products", {"product_id": res['id'], "shop_id": widget.shopId});
        openProduct("/product/${widget.shopId}/${res['id']}", -1);
        return;
      }
    }
    var ret = await Routes.navigateTo(context, "/shop/${widget.shopId}/add/$searchPhrase",
        transition: TransitionType.fadeIn);
    if (ret is Product) {
      getProducts();
    }
  }

  openSendModal() async {
    var ret = await SendData.sendProducts(context);
    if (ret != null && ret is String) {
      Navigator.pop(context);
      Utils.showInSnackBar(_scaffoldKey, ret);
      getProducts();
    }
  }

  openSettings() async {
    await Routes.navigateTo(context, "/settings");
    getProducts();
  }

  openProduct(String path, int i) async {
    var ret = await Routes.navigateTo(context, path, transition: TransitionType.fadeIn);
    if (ret is Product) {
      getProducts();
    }
  }

  openBarcodeSearch() {
    searchBar.beginSearch(context);
    searchBar.scan();
  }
}
