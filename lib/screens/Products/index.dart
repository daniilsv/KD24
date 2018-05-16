import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
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

class ScreenProducts extends StatefulWidget {
  ScreenProducts({Key key, this.shopId, this.category}) : super(key: key);

  final int shopId;
  final String category;

  @override
  ScreenProductsState createState() => new ScreenProductsState();
}

class ScreenProductsState extends State<ScreenProducts> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  Shop shop;
  var items = [];

  String searchPhrase;

  getProducts() async {
    List<Product> _items = [];
    var db = new DataBase();
    db
        .select("p.*")
        .joinLeft("products", "p", "p.id=i.product_id")
        .filterEqual("i.shop_id", widget.shopId)
        .filterEqual("p.category", widget.category)
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
          .filterEqual("p.category", widget.category)
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

  SearchBar searchBar;

  getAppBarTitle() async {
    DataBase db = new DataBase();
    shop = await db.getItemById("shops", widget.shopId, callback: (Map shop) => new Shop.fromJson(shop));
  }

  AppBar buildAppBar(BuildContext context) {
    Widget title = const Text("");
    if (shop != null)
      title = new ListTile(
        title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
        subtitle: new Text(widget.category, style: new TextStyle(color: Colors.white)),
      );
    return new AppBar(
      title: title,
      actions: [searchBar.getSearchAction(context)],
      backgroundColor: Colors.orange,
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
    getProducts();
  }

  void onSearchType(String value) {
    searchPhrase = value;
    getProducts();
  }

  void onSearchClear() {
    searchPhrase = "";
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
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
      body: new ListView.builder(
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
      if (res is Map && res.containsKey("error")) {
        Utils.showInSnackBar(_scaffoldKey, res["error"]);
      } else if (!res.containsKey("error")) {
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
    var ret =
    await Routes.navigateTo(context, "/shop/${widget.shopId}/add/$searchPhrase", transition: TransitionType.fadeIn);
    if (ret is Product) {
      getProducts();
    }
  }

  openProduct(String path, int i) async {
    var ret = await Routes.navigateTo(context, path, transition: TransitionType.fadeIn);
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

  openBarcodeSearch() {
    searchBar.beginSearch(context);
    searchBar.scan();
  }
}
