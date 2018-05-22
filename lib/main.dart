import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/user.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/screens/Login/index.dart';
import 'package:shop_spy/screens/Shops/index.dart';
import 'package:shop_spy/services/database.dart';

void main() {
  Routes.initRoutes();
  startHome();
}

void startHome() async {
  var db = new DataBase();
  if (!await db.open()) {
    await db.open();
  }

  await Config.loadFromDB();
  User user = await User.fromDataBase();
  int now = new DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (user.tokenExpires <= now) {
    runApp(new MaterialApp(title: "Вход", home: new ScreenLogin()));
  } else {
    User.localUser = user;
    runApp(new MaterialApp(title: "KD 24", home: new ScreenShops()));
  }
}
