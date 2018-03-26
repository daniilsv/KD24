import 'dart:io';

import "package:flutter/material.dart";
import 'package:kd24/classes/user.dart';
import 'package:kd24/data/database.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({ Key key }) : super(key: key);

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
    await db.open(join(documentsDirectory.path, "kd24.db"));
    (await db.getRows("config")).forEach((var row) {
      print(row);
    });
    User user = await User.fromDataBase();
    int now = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print("Now is: " + now.toString());
    print("Token expires in: " + (user.tokenExpires - now).toString());

    String path;
    if (user.tokenExpires <= now) {
      path = "/Login";
    } else {
      path = "/Home";
      User.localUser = user;
    }
    Navigator.of(this.context).pushReplacementNamed(path);
  }
}