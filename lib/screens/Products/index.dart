import 'dart:async';

import 'package:async_loader/async_loader.dart';
import 'package:fluro/fluro.dart';
import "package:flutter/material.dart";
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kd24_shop_spy/classes/config.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/components/Drawer/mainDrawer.dart';
import 'package:kd24_shop_spy/components/Search/searchBar.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/http_query.dart';
import 'package:kd24_shop_spy/services/send_data.dart';
import 'package:kd24_shop_spy/services/utils.dart';

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
  var _items = [];

  String searchPhrase;

  getProducts() async {
    if (_items.length == 0 || searchPhrase != null) {
      _items = await _loadFromDatabase();
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
                          new Text("#" + product.order.toString()),
                          product.price != null
                              ? new Text(product.price.toString() ?? "", style: new TextStyle(color: Colors.grey))
                              : const Text(""),
                          product.price != null ? new Icon(FontAwesomeIcons.arrowRight, size: 12.0) : const Text(""),
                          product.priceNew == null
                              ? const Icon(FontAwesomeIcons.times, color: Colors.red)
                              : new Text(product.priceNew.toString() ?? "", style: new TextStyle(color: Colors.green)),
                          new Padding(
                              padding: new EdgeInsets.only(left: 10.0),
                              child: new Text("за ${product.volumeValue} ${product
                                  .volumeText}")),
                          product.priceNew != null && product.isSale ? const Icon(FontAwesomeIcons.star) : const Text(
                              ""),
                        ],
                      ),
                      new Padding(
                        padding: new EdgeInsets.only(top: 5.0),
                      )
                    ]),
                    onPressed: () =>
                        openProduct(
                            "/shop/${widget.shopId}/"
                                "${product.category}/"
                                "${product.id}",
                            index)),
          ))
        ]);
      },
    );
  }

  Future<List> _loadFromDatabase() async {
    List<Product> _items = [];
    var db = await DataBase.getInstance();

    if (!Config.moveDownDone) {
      List<Map> rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}'",
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }
    } else {
      List<Map> rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}' AND `price_new` IS NULL",
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }

      rows = await db.getRows("products",
          where: "`shop_id` = ${widget.shopId} AND `category` = '${widget
              .category}' AND `price_new` IS NOT NULL",
          order: "`name` ASC");
      if (rows.length != 0) {
        for (var product in rows) {
          _items.add(new Product.fromJson(product));
        }
      }
    }
    List<Product> ret = [];
    if (searchPhrase != null && searchPhrase.length > 0) {
      for (var product in _items) {
        var a = Utils.compResult(product.name, searchPhrase);
        var b = Utils.compResult(product.barcode, searchPhrase);
        product.order = a > b ? a : b;
        if (product.order > 10) ret.add(product);
      }
      ret.sort((a, b) => a.order > b.order ? -1 : a.order < b.order ? 1 : 0);
    } else
      ret = _items;
    return ret;
  }

  final GlobalKey<AsyncLoaderState> _productsLoaderState = new GlobalKey<AsyncLoaderState>();

  SearchBar searchBar;

  Future _getAppBarTitle() async {
    DataBase db = await DataBase.getInstance();
    Map _shop = await db.getRow("shops", "`id`=${widget.shopId}");
    shop = new Shop.fromJson(_shop);
    return new ListTile(
      title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
      subtitle: new Text(widget.category, style: new TextStyle(color: Colors.white)),
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
        needBarCodeCamera: true);
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
      floatingActionButton: _getFab(),
      body: new AsyncLoader(
        key: _productsLoaderState,
        initState: () async => await getProducts(),
        renderLoad: () => new Center(child: new CircularProgressIndicator()),
        renderError: ([error]) => new Text('Странно.. Товары не загружаются.'),
        renderSuccess: ({data}) => data,
      ),
    );
  }

  openProductAdd(String barcode) async {
    var ret = await Routes.navigateTo(context, "/shop/${widget.shopId}/${widget.category}/add/$barcode",
        transition: TransitionType.fadeIn);
    if (ret is Product) {
      Routes.navigateTo(context, "/shop/${widget.shopId}/${widget.category}",
          replace: true, transition: TransitionType.fadeIn);
    }
  }

  openProduct(String path, int i) async {
    var ret = await Routes.navigateTo(context, path, transition: TransitionType.fadeIn);
    if (ret is Product) {
      if (!Config.moveDownDone) {
        _items[i] = ret;
        _productsLoaderState.currentState.reloadState();
      } else {
        Routes.navigateTo(context, "/shop/${widget.shopId}/${widget.category}",
            replace: true, transition: TransitionType.fadeIn);
      }
    }
  }

  openSendModal() async {
    var ret = await SendData.sendProducts(context);
    if (ret != null && ret is String) {
      Navigator.pop(context);
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(ret)));
      await new Future.delayed(new Duration(seconds: 1));
      Routes.navigateTo(context, "/shop/${widget.shopId}/${widget.category}",
          replace: true, transition: TransitionType.fadeIn);
    }
  }

  openSettings() async {
    await Routes.navigateTo(context, "/settings");
    Navigator.pop(context);
    Routes.navigateTo(context, "/shop/${widget.shopId}/${widget.category}",
        replace: true, transition: TransitionType.fadeIn);
  }

  _getFab() {
    if (searchPhrase != null && searchPhrase.length >= 8) {
      return new FloatingActionButton(
          child: const Icon(FontAwesomeIcons.plus), onPressed: () => openProductAdd(searchPhrase));
    }
  }
}
