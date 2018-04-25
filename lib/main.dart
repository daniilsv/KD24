import 'package:flutter/material.dart';
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/user.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/screens/Login/index.dart';
import 'package:shop_spy/screens/Shops/index.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/theme/style.dart';

void main() {
  Routes.initRoutes();
  startHome();
}

void startHome() async {
  var db = new DataBase();
  if (!await db.open()) {
    await db.open();
  }

  (await db.get<Map>("config")).forEach((var row) {
    print(row);
  });

  await Config.loadFromDB();
  User user = await User.fromDataBase();
  int now = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
  print("Now is: " + now.toString());
  print("Token expires in: " + (user.tokenExpires - now).toString());

  if (user.tokenExpires <= now) {
    runApp(new MaterialApp(title: "Вход", home: new ScreenLogin(), theme: appTheme));
  } else {
    User.localUser = user;
    runApp(new MaterialApp(title: "KD 24", home: new ScreenShops(), theme: appTheme));
  }
}
