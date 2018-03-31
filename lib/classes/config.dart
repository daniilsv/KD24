import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:kd24_shop_spy/data/database.dart';

@JsonSerializable()
class Config {
  static bool moveDownDone;

  static Future loadFromDB() async {
    DataBase db = await DataBase.getInstance();
    moveDownDone =
        (await db.getField("config", "key='move_down_done'", "value")) == "1";
  }

  static Future saveToDB() async {
    DataBase.getInstance().then((DataBase db) {
      db.updateOrInsert("config", {
        "key": "move_down_done",
        "value": moveDownDone ? "1" : "0",
      });
    });
  }
}
