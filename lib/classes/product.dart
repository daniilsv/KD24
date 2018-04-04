import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Product {
  int id;
  int originalId;
  int shopId;
  String category;
  String name;
  String brand;
  String barcode;
  String volume;
  String volumeValue;
  String image;

  double price;
  double priceNew = 0.0;
  bool isSale = false;
  String datePriceNew;

  Product({this.id,
    this.originalId,
    this.shopId,
    this.name = "",
    this.category = "",
    this.brand,
    this.barcode = "",
    this.volume = "Штука",
    this.volumeValue = "1",
    this.image = "",
    this.price = 0.0,
    this.priceNew = 0.0,
    this.isSale = false,
    this.datePriceNew});

  String get volumeText => volume == "Вес" ? "кг" : volume == "Объем" ? "л" : "шт";

  factory Product.fromJson(Map<String, dynamic> json) =>
      new Product(
          id: json['id'],
          originalId: json['original_id'],
          shopId: json['shop_id'],
          name: json['name'] as String,
          category: json['category'] as String,
          brand: json['brand'] as String,
          barcode: json['barcode'] as String,
          volume: json['volume'] as String,
          volumeValue: json['volume_value'] as String,
          image: json['image'] as String,
          price: json['price'],
          priceNew: json['price_new'],
          isSale: json['is_sale'] == 1,
          datePriceNew: json['price_new_date']);
}
