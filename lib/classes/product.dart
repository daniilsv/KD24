import 'dart:async';

import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';

class Product {
  int id;
  int shopId;
  String category;
  String name;
  String brand;
  String barcode;
  String volume;
  String volumeValue;
  String image;

  double price;
  String date;
  bool isSale = false;
  double priceNew;
  String dateNew;
  bool isSaleNew = false;

  bool isWeight = false;
  bool isPackage = false;

  int order;

  bool isRetailerPackage = false;

  bool isUploaded;

  Product(
      {this.id,
      this.shopId,
      this.name = "",
      this.category = "",
      this.brand, ////////
      this.barcode = "",
      this.volume,
      this.volumeValue = "1",
      this.image = "",
      this.price = 0.0,
      this.date = "",
      this.isSale = false,
      this.priceNew = 0.0,
      this.dateNew = "",
      this.isSaleNew = false,
      this.isUploaded = false});

  String get volumeText {
    switch (volume) {
      case "Вес":
        return "кг";
        break;
      case "Объем":
        return "л";
        break;
      default:
        return "шт";
        break;
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) => new Product(
        id: json['id'] ?? json['product_id'],
        shopId: json['shop_id'],
        name: json['name'] as String,
        category: json['category'] as String,
        brand: json['brand'] as String,
        barcode: json['barcode'] as String,
        volume: json['volume'] as String,
        volumeValue: json['volume_value'] as String,
        image: json['image'] as String,
        price: json['price'] as double,
        date: json['date'],
        isSale: json['is_sale'] == 1,
        priceNew: json['price_new'] as double,
        dateNew: json['date_new'],
        isSaleNew: json['is_sale_new'] == 1,
        isUploaded: json['is_new_uploaded'] == 1,
      );

  static Future fetch(int shopId) async {
    var data =
        await HttpQuery.executeJsonQuery("Products/GetTodayCheckProduct", params: {"retailerId": shopId.toString()});

    if (data is Map && data.containsKey("error")) {
      throw new Exception(data["error"]);
    }

    if ((data as List).length == 0) {
      return false;
    }

    List<Map<String, dynamic>> _products = [];
    List<Map<String, dynamic>> _shopPrice = [];
    for (Map<String, dynamic> product in data) {
      _products.add({
        "id": product['id'],
        "category": product['category'],
        "name": product['name'],
        "brand": product['brand'],
        "barcode": product['barCode'],
        "volume": product['volume'],
        "volume_value": product['volumeValue'],
        "image": product['image']
      });

      _shopPrice.add({
        "product_id": product['id'],
        "shop_id": shopId,
        "price": (product['lastPriceThisRetailer'] as String).length > 2
            ? double.parse(product['lastPriceThisRetailer'])
            : 0.0,
        "date": (product['lastPriceThisRetailerDate'] as String).length > 2 ? product['lastPriceThisRetailerDate'] : 0.0
      });
      _shopPrice.add({
        "product_id": product['id'],
        "shop_id": product['minPriceRetailerId'],
        "price": (product['minPrice'] as String).length > 2 ? product['minPrice'] : 0.0
      });
    }

    var db = new DataBase();
    await db.insertList("products", _products);
    await db.insertList("shop_products", _shopPrice);
    return true;
  }
}
