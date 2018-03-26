import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Product {
  int id;
  int originalId;
  int retailerId;
  String category;
  String name;
  String brand;
  String barCode;
  String volume;
  String volumeValue;
  String image;

  double price;
  double priceNew = 0.0;

  Product(
      {this.id, this.originalId, this.retailerId, this.name, this.category, this.brand, this.barCode,
        this.volume, this.volumeValue, this.image, this.price, this.priceNew});

  factory Product.fromJson(Map<String, dynamic> json) =>
      new Product(
        id: json['id'],
        originalId: json['original_id'],
        retailerId: json['retailer_id'],
        name: json['name'] as String,
        category: json['category'] as String,
        brand: json['brand'] as String,
        barCode: json['barCode'] as String,
        volume: json['volume'] as String,
        volumeValue: json['volumeValue'] as String,
        image: json['image'] as String,
        price: json['price'],
        priceNew: json['price_new'],
      );

  get hasNewPriceIcon =>
      priceNew != null ?
      new Text(priceNew.toString(), style: new TextStyle(color: Colors.green))
          : new Icon(Icons.clear, color: Colors.red, size: 14.0,);

}
