import 'dart:async';

import 'package:async_loader/async_loader.dart';
import 'package:barcode_scan/barcode_scan.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:kd24_shop_spy/classes/config.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/components/Drawer/mainDrawer.dart';
import 'package:kd24_shop_spy/components/Search/searchBar.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/services/http_query.dart';

class ScreenProducts extends StatefulWidget {
  ScreenProducts({Key key, String shopId, this.category}) : super(key: key) {
    this.shopId = int.parse(shopId);
    DataBase.getInstance().then((DataBase db) {
      db.getRow("shops", "`id`=$shopId").then((Map _shop) {
        shop = new Shop.fromJson(_shop);
      });
    });
  }

  int shopId;
  Shop shop;
  String category;

  @override
  ScreenProductsState createState() => new ScreenProductsState();
}

class ScreenProductsState extends State<ScreenProducts> {
  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  var _items = [];

  String searchPhrase;

  getProducts() async {
    if (_items.length == 0 || searchPhrase != null) {
      _items = await _loadFromDatabase();
      if (searchPhrase == null && _items.length == 0) {
        bool status = await _handleRefresh();
        if (status) _items = await _loadFromDatabase();
      }
      searchPhrase = null;
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        Product _product = _items[index];
        return new Row(children: [
          new Expanded(
              child: new Card(
            child: new Stack(children: <Widget>[
              new MaterialButton(
                  height: 50.0,
                  child: new Center(
                      child: new ListTile(
                    title: new Text(_product.name),
                    subtitle: new Text(_product.category),
                    leading: new Column(
                      children: <Widget>[
                        new Image(
                          image: new AdvancedNetworkImage(
                              HttpQuery.hrefTo("prodbasecontent/Images",
                                  baseUrl:
                                      "prodbasestorage.blob.core.windows.net",
                                  file: _product.image),
                              useDiskCache: true),
                          fit: BoxFit.contain,
                          height: 50.0,
                          width: 40.0,
                          alignment: Alignment.center,
                        ),
                        _product.hasNewPriceIcon
                      ],
                    ),
                  )),
                  onPressed: () => null)
            ]),
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
              .category}' AND `price_new` = 'null'" +
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
              .category}' AND `price_new` != 'null'" +
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
        "barCode": product['barCode'],
        "volume": product['volume'],
        "volumeValue": product['volumeValue'],
        "image": product['image']
      });
    }
    var db = await DataBase.getInstance();
    db.insertList("products", _items);
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState =
      new GlobalKey<AsyncLoaderState>();

  SearchBar searchBar;

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      title: new Text('Выберите товар'),
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
        buildDefaultAppBar: buildAppBar);
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
