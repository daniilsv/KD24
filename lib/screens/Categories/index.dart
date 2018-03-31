import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/components/Drawer/mainDrawer.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/http_query.dart';

class ScreenCategories extends StatefulWidget {
  ScreenCategories({Key key, String shopId}) : super(key: key) {
    this.shopId = int.parse(shopId);
  }

  int shopId;
  Shop shop = new Shop();

  @override
  ScreenCategoriesState createState() => new ScreenCategoriesState();
}

class ScreenCategoriesState extends State<ScreenCategories> {
  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

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
            child: new Stack(children: <Widget>[
              new MaterialButton(
                  height: 50.0,
                  child: new Text(
                    _items[index]["category"],
                    style: new TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Routes.navigateTo(
                      context,
                      "/shop/${widget
                                  .shopId}/${_items[index]["category"]}")),
            ]),
          ))
        ]);
      },
    );
  }

  Future<List> _loadCategoriesFromDatabase() async {
    var _categories = [];
    var db = await DataBase.getInstance();
    List<Map> rows = await db.getRows("products",
        where: "`shop_id` = ${widget.shopId}",
        order: "`category` ASC",
        group: "`category`");
    if (rows.length != 0) {
      rows.forEach((var row) {
        _categories.add(row);
      });
    }
    return _categories;
  }

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery.executeJsonQuery("Products/GetTodayCheckProduct",
        params: {"retailerId": widget.shopId.toString()});
    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
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
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState =
      new GlobalKey<AsyncLoaderState>();

  Future _getAppBarTitle() async {
    DataBase db = await DataBase.getInstance();
    Map _shop = await db.getRow("shops", "`id`=${widget.shopId}");
    widget.shop = new Shop.fromJson(_shop);
    return new Text(widget.shop.name,
        style: new TextStyle(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        drawer: new DrawerMain(),
        appBar: new AppBar(
          title: new AsyncLoader(
            initState: () async => await _getAppBarTitle(),
            renderLoad: () =>
            new Center(child: new CircularProgressIndicator()),
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
              renderLoad: () =>
                  new Center(child: new CircularProgressIndicator()),
              renderError: ([error]) =>
                  new Text('Странно.. Товары не загружаются.'),
              renderSuccess: ({data}) => data,
            )));
  }
}
