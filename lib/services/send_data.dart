import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';

class SendData {
  static List<Product> toSend = [];

  static Future<String> sendProducts(BuildContext context) async {
    var db = new DataBase();
    toSend = await db.filterNotNull("date_new").get<Product>("shop_products", callback: (_) => new Product.fromJson(_));

    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        List<Widget> body = [];

        if (toSend.length != 0) {
          body.add(new Text("Вы точно хотите выгрузить обновление цен?"));
          body.add(new Text("Будет выгружена информация о ценах ${toSend.length} товаров"));
        } else
          body.add(new Text("Вы еще не уточнили ни одной цены."));

        body.add(new ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new FlatButton(
              child: new Text('Отмена', style: new TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
          ],
        ));
        if (toSend.length != 0)
          (body.last as ButtonBar).children.add(new FlatButton(
            child: new Text('Выгрузить', style: new TextStyle(color: Colors.green)),
            onPressed: () async {
              String res = await _sendPrices();
              Navigator.of(context).pop(res);
            },
          ));

        return new SizedBox(
          height: 150.0,
          width: MediaQuery.of(context).size.width,
          child: new FittedBox(
            fit: BoxFit.contain,
            child: new Padding(padding: new EdgeInsets.all(16.0), child: new Column(children: body)),
          ),
        );
      },
    );
  }

  static Future<String> _sendPrices() async {
    List<Map> data = [];
    toSend.forEach((Product product) {
      data.add({
        "retailerId": product.shopId,
        "productId": product.id,
        "typeId": product.isSaleNew ? 1 : 0,
        "price1": product.priceNew,
        "date": product.dateNew
      });
    });
    print(data);
    var ret = await HttpQuery.sendData("Prices/sendPriceArray", params: data);

    if ((ret as Map).containsKey("success")) {
      var db = new DataBase();
      for (Product product in toSend) {
        await db
            .filterEqual("product_id", product.id)
            .filterEqual("shop_id", product.shopId)
            .updateFiltered("shop_products", {"price": product.priceNew, "date": product.dateNew, "date_new": null});
      }
      return "${toSend.length} обновлений цен успешно выгружены";
    } else {
      return ret['error'];
    }
  }
}
