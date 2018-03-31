import 'dart:async';

import 'package:async_loader/async_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/classes/user.dart';
import 'package:kd24_shop_spy/components/Buttons/roundedButton.dart';
import 'package:kd24_shop_spy/components/TextFields/inputField.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/services/http_query.dart';
import 'package:kd24_shop_spy/services/utils.dart';
import 'package:kd24_shop_spy/services/validations.dart';
import 'package:kd24_shop_spy/theme/style.dart';

class ScreenProduct extends StatefulWidget {
  ScreenProduct({Key key, this.shopId, this.category, this.id})
      : super(key: key);

  final int shopId;
  final String category;
  final int id;

  @override
  ScreenProductState createState() => new ScreenProductState();
}

class ScreenProductState extends State<ScreenProduct> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AsyncLoaderState> _imageLoaderState =
  new GlobalKey<AsyncLoaderState>();
  Product product = new Product();
  ScrollController scrollController = new ScrollController();
  UserLoginData user = new UserLoginData();
  bool autovalidate = false;
  Shop shop;

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _handleSubmitted() async {
    FormState form = formKey.currentState;
    if (!form.validate()) {
      autovalidate = true;
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      product.datePriceNew = Utils.getDateTimeNow(); //"dd.MM.yyyyTHH:mm:ss"
      DataBase db = await DataBase.getInstance();
      await db.update("products", "`id` = ${product.id}", {
        "is_sale": product.isSale ? 1 : 0,
        "price_new": product.priceNew,
        "price_new_date": product.datePriceNew
      });
      Navigator.pop(context, product);
    }
  }

  Future _getAppBarTitle() async {
    DataBase db = await DataBase.getInstance();
    Map _shop = await db.getRow("shops", "`id`=${widget.shopId}");
    shop = new Shop.fromJson(_shop);
    return new ListTile(
      title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
      subtitle:
      new Text(widget.category, style: new TextStyle(color: Colors.white)),
    );
  }

  Future _getImage() async {
    await new Future.delayed(new Duration(seconds: 1));
    try {
      Widget image = new Image(
        image: new AdvancedNetworkImage(
            HttpQuery.hrefTo("prodbasecontent/Images",
                baseUrl: "prodbasestorage.blob.core.windows.net",
                file: product.image),
            useDiskCache: true),
        fit: BoxFit.contain,
        width: MediaQuery
            .of(context)
            .size
            .width * 0.8,
        height: MediaQuery
            .of(context)
            .size
            .height / 3,
        alignment: Alignment.center,
      );
      return image;
    } on Exception {
      return null;
    }
  }

  @override
  void initState() {
    DataBase.getInstance().then((DataBase db) async {
      Map _product = await db.getRow("products", "`id`=${widget.id}");
      setState(() {
        product = new Product.fromJson(_product);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new AsyncLoader(
          initState: () async => await _getAppBarTitle(),
          renderLoad: () => new Center(child: new CircularProgressIndicator()),
          renderSuccess: ({data}) => data,
        ),
        backgroundColor: Colors.orange,
      ),
      body: new SingleChildScrollView(
        controller: scrollController,
        child: new Container(
          padding: new EdgeInsets.all(16.0),
          child: new Column(
            children: <Widget>[
              new Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Form(
                      key: formKey,
                      autovalidate: autovalidate,
                      child: new Padding(
                        padding: new EdgeInsets.all(8.0),
                        child: new Column(
                          children: <Widget>[
                            new Center(
                              child: new AsyncLoader(
                                key: _imageLoaderState,
                                initState: () async => await _getImage(),
                                renderLoad: () =>
                                new Center(
                                    child: new CircularProgressIndicator()),
                                renderSuccess: ({data}) => data,
                                renderError: ([e]) =>
                                new Center(
                                    child: new CircularProgressIndicator()),
                              ),
                            ),
                            new ListTile(
                              title: new Text(product.name),
                              subtitle: new Text(product.barcode),
                            ),
                            new Divider(color: Colors.black),
                            new Row(
                              children: <Widget>[
                                const Text("Цена за"),
                                new Padding(
                                    padding: new EdgeInsets.only(left: 20.0),
                                    child: new Text(product.volumeValue)),
                                new Padding(
                                  padding: new EdgeInsets.only(left: 20.0),
                                  child: new DropdownButton(
                                      onChanged: (String value) {
                                        product.volume = value;
                                      },
                                      value: product.volume,
                                      items: [
                                        new DropdownMenuItem<String>(
                                          child: const Text("кг."),
                                          value: "Вес",
                                        ),
                                        new DropdownMenuItem<String>(
                                          child: const Text("л."),
                                          value: "Объем",
                                        ),
                                        new DropdownMenuItem<String>(
                                          child: const Text("шт."),
                                          value: "Штука",
                                        ),
                                      ]),
                                )
                              ],
                            ),
                            product.price != null
                                ? new Row(
                              children: <Widget>[
                                const Text("Старая цена: "),
                                new Padding(
                                    padding:
                                    new EdgeInsets.only(left: 20.0),
                                    child: new Text(
                                        product.price.toString()))
                              ],
                            )
                                : const Text(""),
                            new InputField(
                              hintText: "Price",
                              obscureText: false,
                              initialText: product.priceNew == 0.0
                                  ? ""
                                  : product.priceNew.toString(),
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
                                const Text("Акционная цена"),
                                new Checkbox(
                                    onChanged: (bool value) {
                                      setState(() {
                                        product.isSale = value;
                                      });
                                    },
                                    activeColor: Colors.orangeAccent,
                                    value: product.isSale)
                              ],
                            ),
                            new RoundedButton(
                              buttonName: "Сохранить",
                              onTap: () {
                                _handleSubmitted();
                              },
                              width: screenSize.width,
                              height: 50.0,
                              bottomMargin: 10.0,
                              borderWidth: 0.0,
                              buttonColor: primaryColor,
                            ),
                            product.priceNew != null
                                ? product.datePriceNew == null
                                ? new Text("Выгружено",
                                style:
                                new TextStyle(color: Colors.green))
                                : new Text("Не выгружено",
                                style: new TextStyle(color: Colors.red))
                                : const Text("")
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
