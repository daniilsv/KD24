import 'dart:async';

import 'package:async_loader/async_loader.dart';
import "package:flutter/material.dart";
import 'package:kd24/classes/product.dart';
import 'package:kd24/classes/retailer.dart';
import 'package:kd24/components/Buttons/roundedButton.dart';
import 'package:kd24/components/TextFields/inputField.dart';
import 'package:kd24/data/database.dart';
import 'package:kd24/services/http_query.dart';
import 'package:kd24/services/validations.dart';
import 'package:kd24/theme/style.dart';
import 'package:material_search/material_search.dart';

class ScreenRetailer extends StatefulWidget {
  const ScreenRetailer({ Key key, this.retailer, this.category})
      : super(key: key);
  final Retailer retailer;
  final String category;

  @override
  ScreenRetailerState createState() => new ScreenRetailerState();

}

class ScreenRetailerState extends State<ScreenRetailer> {


  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  Future<Null> _askSearch() async {
    await showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new ConstrainedBox(
            constraints: new BoxConstraints(maxHeight: 600.0),
            child: new MaterialSearch<Product>(
              placeholder: 'Search',
              getResults: (String criteria) async {
                DataBase db = await DataBase.getInstance();
                var list = await db.getRows(
                    "products", where: "`name` LIKE '$criteria%'",
                    order: "`name` ASC");
                return list.map((row) =>
                new MaterialSearchResult<Product>(
                    value: new Product.fromJson(row),
                    text: row['name']
                )).toList();
              },
              onSelect: (Product selected) {
                Navigator.of(context).pop();
                _showProduct(selected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Null> _showProduct(Product product) async {
    await showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new ListTile(
            title: new Text(product.name),
            subtitle: new Text(product.category),
          ),
          new ConstrainedBox(
              constraints: new BoxConstraints(
                  maxHeight: 300.0, maxWidth: 300.0),
              child: new Image.network(HttpQuery.hrefTo(
                  "prodbasecontent/Images",
                  baseUrl_: "prodbasestorage.blob.core.windows.net",
                  file: product.image),
                  fit: BoxFit.fitHeight
              )
          ), new RoundedButton(
            buttonName: "Задать цену",
            onTap: () {
              _askPrice(product);
            },
            width: 280.0,
            height: 50.0,
            bottomMargin: 10.0,
            borderWidth: 0.0,
            buttonColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Future<Null> _askPrice(Product product) async {
    await showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new Form(
            key: formKey,
            autovalidate: true,
            child: new Padding(
              padding: new EdgeInsets.all(8.0),
              child: new Column(
                children: <Widget>[
                  new Stack(
                      children: <Widget>[
                        new Padding(
                          padding: new EdgeInsets.only(top: 10.0),
                          child: new SizedBox(
                              height: 50.0,
                              width: 50.0,
                              child: new Image.network(HttpQuery.hrefTo(
                                  "prodbasecontent/Images",
                                  baseUrl_: "prodbasestorage.blob.core.windows.net",
                                  file: product.image),
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              )
                          ),
                        ),
                        new Padding(
                            padding: new EdgeInsets.only(left: 20.0),
                            child: new MaterialButton(
                                height: 50.0,
                                child: new Center(
                                    child: new ListTile(
                                      title: new Text(product.name),
                                      subtitle: new Text(
                                          product.category),
                                    )
                                ),
                                onPressed: () => null
                            )
                        ),
                      ]
                  ),
                  new Divider(
                      color: Colors.black
                  ),
                  new InputField(
                    hintText: "Price",
                    obscureText: false,
                    textInputType: TextInputType.number,
                    textStyle: textStyle,
                    validateFunction: Validations.validatePrice,
                    textFieldColor: textFieldColor,
                    icon: Icons.attach_money,
                    iconColor: Colors.black,
                    bottomMargin: 20.0,
                    onSaved: (String price) {
                      product.priceNew = double.parse(price);
                    },
                  ),
                  new Row(
                    children: <Widget>[
                      new Text("Акционная цена"),
                      new Switch(onChanged: (bool value) {
                        product.isSale = value;
                      }, value: product.isSale)
                    ],
                  ),
                  new RoundedButton(
                    buttonName: "Сохранить",
                    onTap: () {
                      _handleSubmitted(product);
                    },
                    width: 280.0,
                    height: 50.0,
                    bottomMargin: 10.0,
                    borderWidth: 0.0,
                    buttonColor: primaryColor,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  var _items = [];

  getProducts() async {
    if (_items.length == 0) {
      _items = await _loadFromDatabase();
      if (_items.length == 0) {
        bool status = await _handleRefresh();
        if (status)
          _items = await _loadFromDatabase();
      }
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        Product _product = _items[index];
        return new Row(
            children: [
              new Expanded(
                  child: new Card(
                    child: new Stack(
                        children: <Widget>[
                          new MaterialButton(
                              height: 50.0,
                              child: new Center(
                                  child: new ListTile(
                                    title: new Text(_product.name),
                                    subtitle: new Text(_product.category),
                                    leading: new Column(children: <Widget>[
                                      new Image.network(HttpQuery.hrefTo(
                                          "prodbasecontent/Images",
                                          baseUrl_: "prodbasestorage.blob.core.windows.net",
                                          file: _product.image),
                                        fit: BoxFit.contain,
                                        height: 50.0,
                                        width: 40.0,
                                        alignment: Alignment.center,
                                      ),
                                      _product.hasNewPriceIcon
                                    ],
                                    ),
                                  )
                              ),
                              onPressed: () {
                                _showProduct(_product);
                              }
                          )
                        ]
                    ),
                  ))
            ]
        );
      },
    );
  }

  getCategories() async {
    var _items = [];
    if (_items.length == 0) {
      _items = await _loadCategoriesFromDatabase();
      if (_items.length == 0) {
        bool status = await _handleRefresh();
        if (status)
          _items = await _loadCategoriesFromDatabase();
      }
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        return new Row(
            children: [
              new Expanded(
                  child: new Card(
                    child: new Stack(
                        children: <Widget>[
                          new MaterialButton(
                              height: 50.0,
                              child: new Text(
                                _items[index]["category"],
                                style: new TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold
                                ),

                              ),
                              onPressed: () {
                                Navigator.push(
                                    context, new MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                  new ScreenRetailer(
                                      retailer: widget.retailer,
                                      category: _items[index]["category"]),
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

  Future<List> _loadCategoriesFromDatabase() async {
    var _categories = [];
    var db = await DataBase.getInstance();
    List<Map> rows = await db.getRows("products",
        where: "`retailer_id` = ${widget.retailer.id}",
        order: "`category` ASC",
        group: "`category`");
    if (rows.length != 0) {
      rows.forEach((var row) {
        _categories.add(row);
      });
    }
    return _categories;
  }

  Future<List> _loadFromDatabase() async {
    var _items = [];
    var db = await DataBase.getInstance();
    List<Map> rows = await db.getRows("products",
        where: "`retailer_id` = ${widget.retailer.id}" +
            (widget.category != null
                ? " AND `category` = '${widget.category}'"
                : ""),
        order: "`name` ASC");
    if (rows.length != 0) {
      rows.forEach((var product) {
        _items.add(new Product.fromJson(product));
      });
    }
    return _items;
  }

  Future<bool> _handleRefresh() async {
    var data = await HttpQuery.executeJsonQuery(
        "Products/GetTodayCheckProduct",
        params: {
          "retailerId": widget.retailer.id.toString()
        });
    if (data is Map && data.containsKey("error")) {
      showInSnackBar(data["error"]);
      return false;
    }
    if ((data as List).length == 0)
      return false;

    var db = await DataBase.getInstance();
    for (Map product in data) {
      await db.updateOrInsert("products", "`id`=${product['id']}", {
        "original_id": int.parse(product['id']),
        "retailer_id": widget.retailer.id,
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

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<
      RefreshIndicatorState>();
  final GlobalKey<AsyncLoaderState> _productsLoaderState = new GlobalKey<
      AsyncLoaderState>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(
              widget.category != null ? "Выберите товар" : "Выберите категорию",
              style: new TextStyle(
                  color: Colors.white
              )),
          actions: widget.category != null ? <Widget>[
            new MaterialButton(
                height: 50.0,
                child: new Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _askSearch();
                }
            )
          ] : null,
          backgroundColor: Colors.orange,
          centerTitle: true,
        ),
        body: new RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => _handleRefresh(),
            child: new AsyncLoader(
              key: _productsLoaderState,
              initState: () async =>
              widget.category != null
                  ? await getProducts()
                  : await getCategories(),
              renderLoad: () =>
              new Center(child: new CircularProgressIndicator()),
              renderError: ([error]) =>
              new Text('Странно.. Товары не загружаются.'),
              renderSuccess: ({data}) => data,
            )
        )
    );
  }

  void _handleSubmitted(Product product) async {
    FormState form = formKey.currentState;
    if (!form.validate()) {
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      var now = new DateTime.now();
      product.datePriceNew =
      "${_twoDigits(now.day)}.${_twoDigits(now.month)}.${_fourDigits(
          now.year)}T${_twoDigits(
          now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now
          .second)}"; //"dd.MM.yyyyTHH:mm:ss"
      DataBase db = await DataBase.getInstance();
      await db.update("products", "`id` = ${product.id}", {
        "is_sale": product.isSale ? 1 : 0,
        "price_new": product.priceNew,
        "price_new_date": product.datePriceNew
      });
      setState(() {
        _productsLoaderState.currentState.reloadState();
      });
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "${n}";
    return "0${n}";
  }

  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }
}
