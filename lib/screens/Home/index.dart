import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:kd24/classes/product.dart';
import 'package:kd24/classes/retailer.dart';
import 'package:kd24/data/database.dart';
import 'package:kd24/screens/Retailer/index.dart';
import 'package:kd24/services/http_query.dart';
import 'package:material_search/material_search.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({ Key key }) : super(key: key);

  @override
  ScreenHomeState createState() => new ScreenHomeState();

}

class ScreenHomeState extends State<ScreenHome> {

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _wasUpdate = false;

  Future<Null> _askSearch() async {
    await showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new ConstrainedBox(
            constraints: new BoxConstraints(maxHeight: 600.0),
            child: new MaterialSearch<Retailer>(
              placeholder: 'Search', //placeholder of the search bar text input

              getResults: (String criteria) async {
                DataBase db = await DataBase.getInstance();
                var list = await db.getRows(
                    "retailers", where: "`name` LIKE '$criteria%'",
                    order: "`name` ASC");
                return list.map((row) =>
                new MaterialSearchResult<Retailer>(
                    value: new Retailer.fromJson(row),
                    text: row['name'] //String that will be show in the list
                )).toList();
              },
              //callback when some value is selected, optional.
              onSelect: (Retailer selected) {
                Navigator.of(context).pop();
                Navigator.push(
                    context, new MaterialPageRoute(
                  builder: (BuildContext context) =>
                  new ScreenRetailer(retailer: selected),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  getRetailers() async {
    var _items = [];
    if (_items.length == 0 && !_wasUpdate) {
      _items = await _loadFromDatabase();
      if (_items.length == 0) {
        bool status = await _handleRefresh();
        if (status)
          _items = await _loadFromDatabase();
      }
      _wasUpdate = true;
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        var _retailer = _items[index];
        return new Row(
            children: [
              new Expanded(
                  child: new Card(
                    child: new Stack(
                        children: <Widget>[
                          new MaterialButton(
                              height: 50.0,
                              child: new Center(
                                child: new Text(
                                  _retailer.name,
                                  style: new TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold
                                  ),

                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context, new MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                  new ScreenRetailer(retailer: _retailer),
                                ));
                              }
                          ),
                        ]
                    ),
                  ))
            ]
        );
      },
    );
  }

  Future<List> _loadFromDatabase() async {
    var db = await DataBase.getInstance();
    var _items = [];
    List rows = await db.getRows("retailers", order: "`name` ASC");
    if (rows.length != 0) {
      rows.forEach((var retailer) {
        _items.add(new Retailer.fromJson(retailer));
      });
    }
    return _items;
  }

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery.executeJsonQuery("retailers");
    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
      return false;
    }
    if ((data as List).length == 0)
      return false;
    var db = await DataBase.getInstance();
    for (Map retailer in data) {
      await db.updateOrInsert(
          "retailers", "`id`=${retailer['id']}", {
        "id": retailer['id'],
        "name": retailer['name']
      });
    }
    return true;
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<
      RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _retailersLoaderState = new GlobalKey<
      AsyncLoaderState>();
  final GlobalKey<AsyncLoaderState> _toSendLoaderState = new GlobalKey<
      AsyncLoaderState>();

  List<Product> toSend = [];

  getCountToSend() async {
    DataBase db = await DataBase.getInstance();
    var data = await db.getRows("products", where: "`price_new` NOT NULL");

    for (Map product in data) {
      toSend.add(new Product.fromJson(product));
    }
    return toSend.length;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(
              "Выберите магазин",
              style: new TextStyle(
                  color: Colors.white
              )),
          actions: <Widget>[
            new AsyncLoader(
              key: _toSendLoaderState,
              initState: () async => await getCountToSend(),
              renderLoad: () =>
              new Center(child: new CircularProgressIndicator()),
              renderError: ([error]) => const Text(""),
              renderSuccess: ({data}) =>
              new MaterialButton(
                  height: 50.0,
                  child: new Stack(
                    children: <Widget>[
                      new Positioned(
                          child: new Icon(Icons.send, color: Colors.white)),
                      new Positioned(
                          child: new Text(data.toString(),
                              style: new TextStyle(color: Colors.black)))
                    ],
                  ),
                  onPressed: () {
                    _askSearch();
                  }
              ),
            ),
            new MaterialButton(
                height: 50.0,
                child: new Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _askSearch();
                }
            )
          ],
          backgroundColor: Colors.orange,
          centerTitle: true,
        ),
        body: new RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => _handleRefresh(),
            child: new AsyncLoader(
              key: _retailersLoaderState,
              initState: () async => await getRetailers(),
              renderLoad: () =>
              new Center(child: new CircularProgressIndicator()),
              renderError: ([error]) =>
              new Text('Странно.. Магазины не загружаются.'),
              renderSuccess: ({data}) => data,
            )
        )
    );
  }

}