import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';

class SendData {
  static List<Product> toSend = [];
  static List<Map<String, dynamic>> newProducts = [];
  static Map<String, dynamic> newProductsImages = {};

  static Future<String> sendProducts(BuildContext context) async {
    var db = new DataBase();
    toSend = await db.filterNotNull("date_new").get<Product>("shop_products", callback: (_) => new Product.fromJson(_));
    newProducts = [];
    (await db.get<Map<String, dynamic>>("new_products")).forEach((Map<String, dynamic> _) {
      Map<String, dynamic> _i = new Map.from(_);
      newProductsImages[_['barCode']] = _i.remove("image");
      newProducts.add(_i);
    });
    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return new SendDataSheet();
      },
    );
  }
}

class SendDataSheet extends StatefulWidget {
  SendDataSheet({Key key, this.shopId, this.phrase}) : super(key: key);

  final int shopId;
  final String phrase;

  @override
  SendDataSheetState createState() => new SendDataSheetState();
}

class SendDataSheetState extends State<SendDataSheet> {
  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> body = [];
    if (isSending)
      body.add(new Center(child: new CircularProgressIndicator()));
    else {
      if (SendData.toSend.length != 0 && SendData.newProducts.length == 0) {
        body.add(new Text("Вы точно хотите выгрузить обновления цен?"));
        body.add(new Text("Будет выгружена информация о ценах ${SendData.toSend.length} товаров"));
      } else if (SendData.toSend.length == 0 && SendData.newProducts.length != 0) {
        body.add(new Text("Вы точно хотите выгрузить новые товары?"));
        body.add(new Text("Будет выгружена информация ${SendData.newProducts.length} товарах"));
      } else if (SendData.toSend.length != 0 && SendData.newProducts.length != 0) {
        body.add(new Text("Вы точно хотите выгрузить новые товары и обновления цен?"));
        body.add(new Text("Будет выгружена информация ${SendData.newProducts.length} товара и ценах ${SendData.toSend
            .length} товаров"));
      } else
        body.add(new Text("Вы еще не уточнили ни одной цены и не добавили новые товары."));

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
      if (SendData.toSend.length != 0 || SendData.newProducts.length != 0)
        (body.last as ButtonBar).children.add(new FlatButton(
              child: new Text('Выгрузить', style: new TextStyle(color: Colors.green)),
              onPressed: () async {
                setState(() {
                  isSending = true;
                });
                String res = await _sendPrices();
                Navigator.of(context).pop(res);
              },
            ));
    }

    return new SizedBox(
      height: 150.0,
      width: MediaQuery.of(context).size.width,
      child: new FittedBox(
        fit: BoxFit.contain,
        child: new Padding(padding: new EdgeInsets.all(16.0), child: new Column(children: body)),
      ),
    );
  }

  static Future<String> _sendPrices() async {
    String error = "", success = "";
    DataBase db = new DataBase();
    if (SendData.newProducts.length != 0) {
      var ret = await HttpQuery.sendData("Products/SendTodayCheckProduct", params: SendData.newProducts);
      if (ret is List) {
        ret.forEach((r) {
          if (!(r is Map)) return;
          try {
            File _imageFile = new File(SendData.newProductsImages[r['barCode']]);
            img.Image image = img.decodeImage(_imageFile.readAsBytesSync());
            img.Image thumbnail = img.copyResize(image, image.width * 512 ~/ image.height, 512);
            HttpQuery.sendData("ImagesUpload", params: thumbnail.getBytes(), query: {
              "name": "${r['barcode']}.${_imageFile.path
                  .split(".")
                  .last}"
            });
            _imageFile.delete();
          } catch (e) {}
          db.delete("new_products", r['barCode'], field: "barCode");
        });
        success += "${SendData.newProducts.length} новых товаров успешно выгружены\n";
      } else {
        error += ret['error'] + "\n";
      }
    }
    if (SendData.toSend.length != 0) {
      List<Map> data = [];
      SendData.toSend.forEach((Product product) {
        data.add({
          "retailerId": product.shopId,
          "productId": product.id,
          "typeId": product.isSaleNew ? 1 : 0,
          "price1": product.priceNew,
          "date": product.dateNew
        });
      });

      var ret = await HttpQuery.sendData("Prices/sendPriceArray", params: data);

      if ((ret as Map).containsKey("success")) {
        for (Product product in SendData.toSend) {
          await db
              .filterEqual("product_id", product.id)
              .filterEqual("shop_id", product.shopId)
              .updateFiltered("shop_products", {"price": product.priceNew, "date": product.dateNew, "date_new": null});
        }
        success += "${SendData.toSend.length} обновлений цен успешно выгружены";
      } else {
        error += ret['error'];
      }
    }
    return success + (error != "" ? "\n" + error : "");
  }
}
