import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/services/http_query.dart';

class SendData {
  static List<Product> toSend = [];

  static Future<String> sendProducts(BuildContext context) async {
    var db = new DataBase();
    var rows = await db.filterNotNull("date_new").get("shop_products");
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
        "retailerId": product.shopId,
        "productId": product.originalId,
        "typeId": product.isSale ? 1 : 0,
        "price1": product.priceNew,
        "date": product.datePriceNew
      });
    });
    var ret = await HttpQuery.sendData("Prices/sendPriceArray", params: json.encode(data));

    if ((ret as Map).containsKey("success")) {
      var db = new DataBase();
      for (Product product in toSend) {
        await db.update("products", "`id`=${product.id}", {"price": product.priceNew, "price_new_date": null});
      }
      return "${toSend.length} обновлений цен успешно выгружены";
    } else {
      return "Что-то пошло не так...";
    }
  }
}
