import 'dart:async';

import "package:flutter/material.dart";
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/database.dart';
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

  @override
  void initState() {
    super.initState();
    getAppBarTitle();
    getCategories();
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
    Widget title = const Text("");
    if (shop != null) title = new Text(shop.name, style: new TextStyle(color: Colors.white));
    return new Scaffold(
      key: _scaffoldKey,
      drawer: new DrawerMain(),
      appBar: new AppBar(
        title: title,
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _handleRefresh<Null>(true),
        child: new ListView.builder(
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
        ),
      ),
    );
  }
}
