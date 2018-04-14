import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:kd24_shop_spy/data/database.dart';

@JsonSerializable()
class Config {
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
