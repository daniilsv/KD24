import 'dart:async';

import 'package:kd24_shop_spy/data/database.dart';

class Config {
  static final String dbName = "kd24_shop_spy";
  static final int dbVersion = 1;

  static bool moveDownDone;

  static Future loadFromDB() async {
    DataBase db = new DataBase();
    moveDownDone = (await db.getField("config", "move_down_done", "value", filterField: "key")) == "1";
  }

  static Future saveToDB() async {
    DataBase db = new DataBase();
    db.updateOrInsert("config", {
      "key": "move_down_done",
      "value": moveDownDone ? "1" : "0",
    });
  }
}
