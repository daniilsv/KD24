import 'dart:io';

import "package:flutter/material.dart";
import 'package:kd24_shop_spy/classes/config.dart';
import 'package:kd24_shop_spy/classes/user.dart';
import 'package:kd24_shop_spy/data/database.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({Key key}) : super(key: key);

  @override
  ScreenSplashState createState() => new ScreenSplashState();
}

class ScreenSplashState extends State<ScreenSplash> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold();
  }

  @override
  void initState() {
    super.initState();
    _startHome();
  }

  void _startHome() async {
    DataBase db = await DataBase.getInstance();

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    await db.open(join(documentsDirectory.path, "kd24_shop_spy.db"));
    (await db.getRows("config")).forEach((var row) {
      print(row);
    });
    Config.loadFromDB();
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
    Routes.navigateTo(this.context, path, replace: true);
  }
}
