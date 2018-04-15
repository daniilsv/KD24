import "package:flutter/material.dart";
import 'package:shop_spy/classes/config.dart';
import 'package:shop_spy/classes/user.dart';
import 'package:shop_spy/data/database.dart';
import 'package:shop_spy/routes.dart';

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
    Routes.navigateTo(this.context, path, replace: true);
  }
}
