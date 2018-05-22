import 'dart:async';

import "package:flutter/material.dart";
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Drawer/mainDrawer.dart';
import 'package:shop_spy/components/Search/searchBar.dart';
import 'package:shop_spy/screens/Shops/shops_list.dart';
import 'package:shop_spy/services/database.dart';
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

  String searchPhrase;

  List<Shop> items = [];

  getShops() async {
    items = await loadShops();
    if (searchPhrase == null && items.length == 0) {
      await fetchShops();
    }
    setState(() {});
  }

  fetchShops() async {
    try {
      if (await Shop.fetch()) items = await loadShops();
    } catch (e) {
      Utils.showInSnackBar(_scaffoldKey, e.toString());
    }
    setState(() {});
  }

  Future<List<Shop>> loadShops() async {
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

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

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
    getShops();
  }

  void onSearchType(String value) {
    searchPhrase = value;
  }

  void onSearchClear() {
    searchPhrase = "";
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
        backgroundColor: Colors.deepOrange,
        child: new Icon(FontAwesomeIcons.telegramPlane, color: Colors.white),
        onPressed: () => openSendModal(false),
      ),
      appBar: searchBar.build(context),
      body: new RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => fetchShops(),
        child: new ShopsList(shops: items),
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
