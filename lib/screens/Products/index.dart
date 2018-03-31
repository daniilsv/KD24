import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:kd24_shop_spy/classes/config.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/components/Drawer/mainDrawer.dart';
import 'package:kd24_shop_spy/components/Search/searchBar.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/http_query.dart';
import 'package:kd24_shop_spy/services/utils.dart';

class ScreenProducts extends StatefulWidget {
  ScreenProducts({Key key, String shopId, this.category}) : super(key: key) {
    this.shopId = int.parse(shopId);
  }

  int shopId;
  Shop shop;
  String category;

  @override
  ScreenProductsState createState() => new ScreenProductsState();
}

class ScreenProductsState extends State<ScreenProducts> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  var _items = [];

  String searchPhrase;
  static bool wasUpdate = false;

  getProducts() async {
    if (_items.length == 0 || (wasUpdate && searchPhrase != null)) {
      _items = await _loadFromDatabase();
      if (searchPhrase == null && _items.length == 0) {
        bool status = await _handleRefresh();
        if (status) _items = await _loadFromDatabase();
      }
      wasUpdate = true;
      searchPhrase = null;
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        Product product = _items[index];
        return new Row(children: [
          new Expanded(
              child: new Card(
                child: new MaterialButton(
                    child: new Column(children: <Widget>[
                      new ListTile(
                        title: new Text(product.name),
                        subtitle: new Text(product.barcode),
                        leading: new Image(
                          image: new AdvancedNetworkImage(
                              HttpQuery.hrefTo("prodbasecontent/Images",
                                  baseUrl: "prodbasestorage.blob.core.windows.net",
                                  file: product.image),
                              useDiskCache: true),
                          fit: BoxFit.contain,
                          height: 80.0,
                          width: 40.0,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      new Row(
                        children: <Widget>[
                          new Text(product.price ?? "",
                              style: new TextStyle(color: Colors.grey)),
                          product.price != null
                              ? new Icon(Icons.arrow_forward, size: 12.0)
                              : new Text(""),
                          product.priceNew == null
                              ? new Icon(Icons.close, color: Colors.red)
                              : new Text(product.priceNew ?? "",
                              style: new TextStyle(color: Colors.green)),
                          new Text("за " +
                              product.volumeValue +
                              " " +
                              product.volumeText),
                          product.priceNew == null
                              ? new Text("")
                              : product.isSale
                              ? new Icon(Icons.star)
                              : new Icon(Icons.star_border),
                        ],
                      )
                    ]),
                    onPressed: () =>
                        Routes.navigateTo(context, "/product/${product.id}")),
          ))
        ]);
      },
    );
  }

  Future<List> _loadFromDatabase() async {
    var _items = [];
    var db = await DataBase.getInstance();

    if (!Config.moveDownDone) {
      List<Map> rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}'" +
              (searchPhrase != null
                  ? " AND `name` LIKE '$searchPhrase%' OR `barcode` LIKE '$searchPhrase%'"
                  : ""),
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }
    } else {
      List<Map> rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}' AND `price_new` IS NULL" +
              (searchPhrase != null
                  ? " AND `name` LIKE '$searchPhrase%' OR `barcode` LIKE '$searchPhrase%'"
                  : ""),
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }

      rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}' AND `price_new` IS NOT NULL" +
              (searchPhrase != null
                  ? " AND `name` LIKE '$searchPhrase%' OR `barcode` LIKE '$searchPhrase%'"
                  : ""),
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }
    }
    return _items;
  }

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery.executeJsonQuery("Products/GetTodayCheckProduct",
        params: {"retailerId": widget.shopId.toString()});
    if (data is Map && data.containsKey("error")) {
      Utils.showInSnackBar(_scaffoldKey, data["error"]);
      return false;
    }
    if ((data as List).length == 0) return false;

    List<Map> _items = [];
    for (Map product in data) {
      _items.add({
        "original_id": int.parse(product['id']),
        "shop_id": widget.shopId,
        "category": product['category'],
        "name": product['name'],
        "brand": product['brand'],
        "barcode": product['barCode'],
        "volume": product['volume'],
        "volume_value": product['volumeValue'],
        "image": product['image']
      });
    }
    var db = await DataBase.getInstance();
    await db.insertList("products", _items);
    wasUpdate = false;
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState =
      new GlobalKey<AsyncLoaderState>();

  SearchBar searchBar;

  Future _getAppBarTitle() async {
    DataBase db = await DataBase.getInstance();
    Map _shop = await db.getRow("shops", "`id`=${widget.shopId}");
    widget.shop = new Shop.fromJson(_shop);
    return new ListTile(
      title:
      new Text(widget.shop.name, style: new TextStyle(color: Colors.white)),
      subtitle:
      new Text(widget.category, style: new TextStyle(color: Colors.white)),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      title: new AsyncLoader(
        initState: () async => await _getAppBarTitle(),
        renderLoad: () => new Center(child: new CircularProgressIndicator()),
        renderSuccess: ({data}) => data,
      ),
      actions: [searchBar.getSearchAction(context)],
      backgroundColor: Colors.orange,
    );
  }

  @override
  void initState() {
    super.initState();
    searchBar = new SearchBar(
      inBar: true,
      setState: setState,
      onType: onSearchType,
      onSubmitted: onSearchType,
      onClear: onSearchClear,
      buildDefaultAppBar: buildAppBar,
    );
  }

  void onSearchType(String value) {
    searchPhrase = value;
    _productsLoaderState.currentState.reloadState();
  }

  void onSearchClear() {
    searchPhrase = "";
    _productsLoaderState.currentState.reloadState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        drawer: new DrawerMain(),
        appBar: searchBar.build(context),
        body: new RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => _handleRefresh(),
            child: new AsyncLoader(
              key: _productsLoaderState,
              initState: () async => await getProducts(),
              renderLoad: () =>
                  new Center(child: new CircularProgressIndicator()),
              renderError: ([error]) =>
                  new Text('Странно.. Товары не загружаются.'),
              renderSuccess: ({data}) => data,
            )));
  }
}
