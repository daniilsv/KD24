import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/data/database.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/http_query.dart';

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

  getCategories() async {
    var _items = [];
    if (_items.length == 0) {
      _items = await _loadCategoriesFromDatabase();
      if (_items.length == 0) {
        bool status = await _handleRefresh();
        if (status) _items = await _loadCategoriesFromDatabase();
      }
    }

    return new ListView.builder(
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

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery
        .executeJsonQuery("Products/GetTodayCheckProduct", params: {"retailerId": widget.shopId.toString()});

    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
      return false;
    }

    if ((data as List).length == 0) return false;

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
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState = new GlobalKey<AsyncLoaderState>();

  Future _getAppBarTitle() async {
    var db = new DataBase();
    shop = await db.getItemById("shops", widget.shopId, callback: (Map shop) => new Shop.fromJson(shop));
    return new Text(shop.name, style: new TextStyle(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      drawer: new DrawerMain(),
      appBar: new AppBar(
        title: new AsyncLoader(
          initState: () async => await _getAppBarTitle(),
          renderLoad: () => const Center(),
          renderSuccess: ({data}) => data,
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _handleRefresh(),
        child: new AsyncLoader(
          key: _productsLoaderState,
          initState: () async => await getCategories(),
          renderLoad: () => new Center(child: new CircularProgressIndicator()),
          renderError: ([error]) => new Text('Странно.. Категории не загружаются.'),
          renderSuccess: ({data}) => data,
        ),
      ),
    );
  }
}
