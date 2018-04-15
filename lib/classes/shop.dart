class Shop {
  int id;
  String name;
  bool isVisible;
  bool isVisibleApk;
  int order;

  Shop({this.id, this.name = "", this.isVisible, this.isVisibleApk});

  factory Shop.fromJson(Map<String, dynamic> json) => new Shop(
        id: json['id'],
        name: json['name'] as String,
        isVisible: json['isVisible'] as bool,
        isVisibleApk: json['isVisibleApk'] as bool,
      );
}
