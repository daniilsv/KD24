import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/http_query.dart';

class Utils {
  static String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static List<Product> toSend = [];

  static Future<String> sendProducts(BuildContext context) async {
    DataBase db = await DataBase.getInstance();
    var rows = await db.getRows("products", where: "`price_new_date` IS NOT NULL");
    toSend = [];
    for (Map product in rows) {
      toSend.add(new Product.fromJson(product));
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      child: new AlertDialog(
        title: new Text('Выгрузить цены'),
        content: new SingleChildScrollView(
          child: new ListBody(
            children: toSend.length != 0
                ? <Widget>[
              new Text("Вы точно хотите выгрузить обновление цен?"),
              new Text("Будет выгружена информация о ценах ${toSend
                  .length} товаров")
            ]
                : <Widget>[
              new Text("Вы еще не уточнили ни одной цены."),
            ],
          ),
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('Отмена', style: new TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          toSend.length != 0
              ? new FlatButton(
            child: new Text('Выгрузить', style: new TextStyle(color: Colors.green)),
            onPressed: () async {
              String res = await _sendPrices();
              Navigator.of(context).pop(res);
            },
          )
              : new Text(""),
        ],
      ),
    );
  }

  static Future<String> _sendPrices() async {
    List<Map> data = [];
    toSend.forEach((Product product) {
      data.add({
        "shopId": product.shopId,
        "productId": product.originalId,
        "typeId": product.isSale ? 1 : 0,
        "price": product.priceNew,
        "date": product.datePriceNew
      });
    });
    var ret = await HttpQuery.sendData("Prices/sendPriceArray", method: "post", params: json.encode(data));

    if ((ret as Map).containsKey("success")) {
      DataBase db = await DataBase.getInstance();
      for (Product product in toSend) {
        await db.update("products", "`id`=${product.id}", {"price": product.priceNew, "price_new_date": null});
      }
      return "${toSend.length} обновлений цен успешно выгружены";
    } else {
      return "Что-то пошло не так...";
    }
  }

  static logout(BuildContext context) async {
    DataBase db = await DataBase.getInstance();
    db.delete("config", "`key`='token'");
    db.delete("config", "`key`='token_type'");
    db.delete("config", "`key`='token_expires'");
    Routes.backTo(context, "/shops");
    Routes.navigateTo(context, "/login", replace: true);
  }

  static showInSnackBar(GlobalKey<ScaffoldState> key, String value) {
    key.currentState.showSnackBar(new SnackBar(content: new Text(value)));
  }

  static String getDateTimeNow() {
    var now = new DateTime.now();
    return "${twoDigits(now.day)}"
        ".${twoDigits(now.month)}"
        ".${fourDigits(now.year)}"
        "T${twoDigits(now.hour)}"
        ":${twoDigits(now.minute)}"
        ":${twoDigits(now.second)}";
  }
}
