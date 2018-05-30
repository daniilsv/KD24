import 'dart:async';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/components/Search/searchBar.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/screens/Products/categories_list.dart';
import 'package:shop_spy/screens/Products/products_list.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';
import 'package:shop_spy/services/send_data.dart';
import 'package:shop_spy/services/utils.dart';

class ScreenProducts extends StatefulWidget {
  ScreenProducts({Key key, this.shopId}) : super(key: key);

  final int shopId;

  @override
  ScreenProductsState createState() => new ScreenProductsState();
}

class ScreenProductsState extends State<ScreenProducts> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  Shop shop;
  String categoryName;
  List<String> categories = [];
  List<Product> products = [];

  String searchPhrase;
  SearchBar searchBar;
  bool isProducts = false;
  bool isLoading = false;

  getCategories() async {
    categories = await loadCategories();
    if (categories.length == 0 || new DateTime.now().difference(shop.last).inHours >= 14) {
      new DataBase().update("shops", widget.shopId, {"last": new DateTime.now().toString()});
      await fetchProducts();
      categories = await loadCategories();
    }
    setState(() {});
  }

  Future<List<String>> loadCategories() async => await new DataBase()
      .selectOnly("p.category")
      .joinLeft("products", "p", "p.id=i.product_id")
      .filterEqual("shop_id", widget.shopId)
      .orderBy("p.category")
      .groupBy("p.category")
      .get<String>("shop_products", callback: (var row) => row['category']);

  getProducts() async {
    setState(() {
      isLoading = true;
    });
    products = await loadProducts();
    if (searchPhrase == null && products.length == 0) {
      await fetchProducts();
    }
    setState(() {
      isLoading = false;
    });
  }

  fetchProducts() async {
    try {
      if (await Product.fetch(widget.shopId)) products = await loadProducts();
    } catch (e) {
      Utils.showInSnackBar(_scaffoldKey, e.toString());
    }
    setState(() {});
  }

  Future<List<Product>> loadProducts() async {
    List<Product> _items = [];
    var db = new DataBase();
    db
        .select("p.*")
        .joinLeft("products", "p", "p.id=i.product_id")
        .filterEqual("i.shop_id", widget.shopId)
        .orderBy("p.name");

    if (categoryName != null) db.filterEqual("p.category", categoryName);

    if (!Config.moveDownDone) {
      List<Product> rows = await db.get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);
    } else {
      List<Product> rows = await db
          .filterIsNull("price_new")
          .get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);

      if (categoryName != null) db.filterEqual("p.category", categoryName);
      rows = await db
          .select("p.*")
          .joinLeft("products", "p", "p.id=i.product_id")
          .filterEqual("i.shop_id", widget.shopId)
          .filterEqual("p.category", categoryName)
          .orderBy("p.name")
          .filterNotNull("price_new")
          .get<Product>("shop_products", callback: (Map item) => new Product.fromJson(item));
      _items.addAll(rows);
    }
    if (searchPhrase == null || searchPhrase.length == 0) return _items;
    List<Product> items = [];
    for (var product in _items) {
      var a = Utils.compResult(product.name, searchPhrase);
      var b = Utils.compResult(product.barcode, searchPhrase);
      product.order = a > b ? a : b;
      if (product.order > 10) items.add(product);
    }
    items.sort((a, b) => a.order > b.order ? -1 : a.order < b.order ? 1 : 0);
    return items;
  }

  loadShop() async =>
      shop = await new DataBase().getItemById("shops", widget.shopId, callback: (Map shop) => new Shop.fromJson(shop));

  @override
  void initState() {
    super.initState();
    loadShop();
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

  void onSearchType(String value) {
    if (value == null) return onSearchClear();
    searchPhrase = value;
    isProducts = true;
    getProducts();
  }

  void onSearchClear() {
    searchPhrase = null;
    if (categoryName == null)
      setState(() {
        isProducts = false;
      });
    else
      getProducts();
  }

  AppBar buildAppBar(BuildContext context) {
    Widget title = const Text("");
    if (categoryName != null)
      title = new ListTile(
        title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
        subtitle: new SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 20.0,
          child: new FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: new Text(categoryName, style: new TextStyle(color: Colors.white)),
          ),
        ),
      );
    else if (shop != null) title = new Text(shop.name, style: new TextStyle(color: Colors.white));

    return new AppBar(
      title: title,
      actions: [searchBar.getSearchAction(context)],
      backgroundColor: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isProducts)
      body = new ProductsList(products: products, openProduct: openProduct, isLoading: isLoading);
    else
      body = new CategoriesList(categories: categories, openCategory: openCategory);

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
      body: body,
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
        openProduct(prod.id);
        return;
      }
      var res = await HttpQuery.executeJsonQuery("Products/GetProductCheck", params: {"barCode": searchPhrase});
      if (res is Map && res.containsKey("error")) {
        Utils.showInSnackBar(_scaffoldKey, res["error"]);
      } else if (res is Map && !res.containsKey("error")) {
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
        openProduct(res['id']);
        return;
      }
    }
    var ret =
        await Routes.navigateTo(context, "/shop/${widget.shopId}/add/$searchPhrase", transition: TransitionType.fadeIn);
    if (ret is String) {
      Utils.showInSnackBar(_scaffoldKey, ret);
      getProducts();
    }
  }

  openProduct(int productId) async {
    var ret =
        await Routes.navigateTo(context, "/product/${widget.shopId}/$productId", transition: TransitionType.fadeIn);
    if (ret is String) {
      Utils.showInSnackBar(_scaffoldKey, ret);
      getProducts();
    }
  }

  openCategory(String categoryName) async {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(onRemove: () {
      setState(() {
        this.categoryName = null;
        isProducts = false;
      });
    }));
    this.categoryName = categoryName;
    getProducts();
    setState(() {
      isProducts = true;
    });
  }

  openSendModal() async {
    var ret = await SendData.sendProducts(context);
    if (ret != null && ret is String) {
      Navigator.pop(context);
      Utils.showInSnackBar(_scaffoldKey, ret);
      if (isProducts)
        getProducts();
      else
        getCategories();
    }
  }

  openSettings() async {
    await Routes.navigateTo(context, "/settings");
    if (isProducts) getProducts();
  }

  openBarcodeSearch() {
    searchBar.beginSearch(context);
    isProducts = true;
    searchBar.scan();
  }
}
