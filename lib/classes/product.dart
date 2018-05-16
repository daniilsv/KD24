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

  Product({this.id,
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

  factory Product.fromJson(Map<String, dynamic> json) =>
      new Product(
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
}
