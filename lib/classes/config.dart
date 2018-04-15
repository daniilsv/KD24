import 'dart:async';

import 'package:shop_spy/data/database.dart';

class Config {
  static final String dbName = "shop_spy";
  static final int dbVersion = 1;

  static bool moveDownDone;

  static Future loadFromDB() async {
    var db = new DataBase();
    moveDownDone = (await db.getField("config", "move_down_done", "value", filterField: "key")) == "1";
  }

  static Future saveToDB() async {
    var db = new DataBase();
    db.updateOrInsert("config", {
      "key": "move_down_done",
      "value": moveDownDone ? "1" : "0",
    });
  }
}
