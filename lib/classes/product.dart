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
  String date;
  double priceNew;
  String dateNew;
  bool isSaleNew = false;

  int order;

  Product({this.id,
    this.originalId,
    this.shopId,
    this.name = "",
    this.category = "",
    this.brand,
    this.barcode = "",
    this.volume,
    this.volumeValue = "1",
    this.image = "",
    this.price = 0.0,
    this.date = "",
    this.priceNew = 0.0,
    this.dateNew = "",
    this.isSaleNew = false});

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

  factory Product.fromJson(Map<String, dynamic> json) =>
      new Product(
        id: json['id'],
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
        priceNew: json['price_new'] as double,
        dateNew: json['date_new'],
        isSaleNew: json['is_sale_new'] == 1,
      );
}
