import 'dart:async';

import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';

class Shop {
  int id;
  String name;
  bool isVisible;
  bool isVisibleApk;
  int order;
  DateTime last;

  Shop({this.id, this.name = "", this.isVisible, this.isVisibleApk, this.last});

  factory Shop.fromJson(Map<String, dynamic> json) => new Shop(
        id: json['id'],
        name: json['name'] as String,
        isVisible: json['isVisible'] as bool,
        isVisibleApk: json['isVisibleApk'] as bool,
        last: DateTime.parse(json['last'] as String),
      );

  static Future<bool> fetch() async {
    var data = await HttpQuery.executeJsonQuery("retailers");
    if (data is Map && data.containsKey("error")) {
      throw new Exception(data["error"]);
    }
    if ((data as List).length == 0) return false;

    List<Map<String, dynamic>> _items = [];
    for (Map shop in data) {
      _items.add({
        "id": shop['id'],
        "name": shop['name'],
        "last": new DateTime.now().add(new Duration(days: -1)).toString(),
      });
    }
    var db = new DataBase();
    await db.insertList("shops", _items);
    return true;
  }
}
