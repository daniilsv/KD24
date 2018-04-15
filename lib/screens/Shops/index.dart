import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/components/Search/searchBar.dart';
import 'package:shop_spy/data/database.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/http_query.dart';
import 'package:shop_spy/services/send_data.dart';
import 'package:shop_spy/services/utils.dart';

class ScreenShops extends StatefulWidget {
  const ScreenShops({Key key}) : super(key: key);

  @override
  ScreenShopsState createState() => new ScreenShopsState();
}

class ScreenShopsState extends State<ScreenShops> {
  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(value)));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _wasUpdate = false;
  String searchPhrase;

  getShops() async {
    var _items = [];
    if (_items.length == 0 && !_wasUpdate || searchPhrase != null) {
      _items = await _loadFromDatabase();
      if (searchPhrase == null && _items.length == 0) {
        bool status = await _handleRefresh();
        if (status) _items = await _loadFromDatabase();
      }
      _wasUpdate = true;
      searchPhrase = null;
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        var shop = _items[index];
        return new Row(children: [
          new Expanded(
            child: new Card(
              child: new MaterialButton(
                  height: 50.0,
                  child: new ListTile(
                    title: new Text(
                      shop.name,
                      style: new TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onPressed: () => Routes.navigateTo(context, "/shop/${shop.id}")),
            ),
          )
        ]);
      },
    );
  }

  Future<List> _loadFromDatabase() async {
    await new Future.delayed(new Duration(seconds: 1));
    var db = new DataBase();
    List<Shop> _items = await db.orderBy("name").get<Shop>("shops", callback: (Map item) => new Shop.fromJson(item));

    List<Shop> ret = [];
    if (searchPhrase != null && searchPhrase.length > 0) {
      for (var shop in _items) {
        shop.order = Utils.compResult(shop.name, searchPhrase);
        if (shop.order > 10) ret.add(shop);
      }
      ret.sort((a, b) => a.order > b.order ? -1 : a.order < b.order ? 1 : 0);
    } else
      ret = _items;
    return ret;
  }

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery.executeJsonQuery("retailers");
    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
      return false;
    }
    if ((data as List).length == 0) return false;

    List<Map<String, dynamic>> _items = [];
    for (Map shop in data) {
      _items.add({"id": shop['id'], "name": shop['name']});
    }
    var db = new DataBase();
    await db.insertList("shops", _items);
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _shopsLoaderState = new GlobalKey<AsyncLoaderState>();

  SearchBar searchBar;

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      title: new Text('Выберите магазин'),
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
    _shopsLoaderState.currentState.reloadState();
  }

  void onSearchClear() {
    searchPhrase = "";
    _shopsLoaderState.currentState.reloadState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      drawer: new DrawerMain(
        sendWidget: new ListTile(
          leading: const Icon(FontAwesomeIcons.telegramPlane),
          title: new Text('Отправить изменения'),
          onTap: () => openSendModal(true),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Colors.green,
        child: new Icon(FontAwesomeIcons.telegramPlane, color: Colors.white),
        onPressed: () => openSendModal(false),
      ),
      appBar: searchBar.build(context),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _handleRefresh(),
        child: new AsyncLoader(
          key: _shopsLoaderState,
          initState: () async => await getShops(),
          renderLoad: () => new Center(child: new CircularProgressIndicator()),
          renderError: ([error]) => new Text('Странно.. Магазины не загружаются.'),
          renderSuccess: ({data}) => data,
        ),
      ),
    );
  }

  openSendModal(bool pop) async {
    var ret = await SendData.sendProducts(context);
    if (ret != null && ret is String) {
      if (pop) Navigator.pop(context);
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(ret)));
    }
  }
}
