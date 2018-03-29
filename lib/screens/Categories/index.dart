import 'dart:async';

import 'package:async_loader/async_loader.dart';
import 'package:barcode_scan/barcode_scan.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/components/Drawer/mainDrawer.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/http_query.dart';

class ScreenCategories extends StatefulWidget {
  ScreenCategories({Key key, String shopId}) : super(key: key) {
    this.shopId = int.parse(shopId);
    DataBase.getInstance().then((DataBase db) {
      db.getRow("shops", "`id`=$shopId").then((Map _shop) {
        shop = new Shop.fromJson(_shop);
      });
    });
  }

  int shopId;
  Shop shop;

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

    var db = await DataBase.getInstance();
    for (Map product in data) {
      await db.updateOrInsert("products", "`id`=${product['id']}", {
        "original_id": int.parse(product['id']),
        "shop_id": widget.shopId,
        "category": product['category'],
        "name": product['name'],
        "brand": product['brand'],
        "barCode": product['barCode'],
        "volume": product['volume'],
        "volumeValue": product['volumeValue'],
        "image": product['image']
      });
    }
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState =
      new GlobalKey<AsyncLoaderState>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        drawer: new DrawerMain(),
        appBar: new AppBar(
          title: new Text("Выберите категорию",
              style: new TextStyle(color: Colors.white)),
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

  String barcode = "";

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        this.barcode = barcode;
        print(this.barcode);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }
}
