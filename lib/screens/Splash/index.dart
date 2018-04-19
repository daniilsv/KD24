import "package:flutter/material.dart";
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/user.dart';
import 'package:shop_spy/data/database.dart';
import 'package:shop_spy/routes.dart';

class ScreenSplash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _startHome(context);
    return new Center(child: new Text("Начинаем..."));
  }

  void _startHome(BuildContext context) async {
    var db = new DataBase();
    await db.open();

    (await db.get<Map>("config")).forEach((var row) {
      print(row);
    });

    await Config.loadFromDB();
    User user = await User.fromDataBase();
    int now = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print("Now is: " + now.toString());
    print("Token expires in: " + (user.tokenExpires - now).toString());

    String path;
    if (user.tokenExpires <= now) {
      path = "/login";
    } else {
      path = "/shops";
      User.localUser = user;
    }
    Routes.navigateTo(context, path, replace: true);
  }
}
