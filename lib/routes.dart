import 'package:flutter/material.dart';
import 'package:kd24/screens/Home/index.dart';
import 'package:kd24/screens/Login/index.dart';
import 'package:kd24/screens/Splash/index.dart';
import 'package:kd24/theme/style.dart';

class Routes {

  var routes = <String, WidgetBuilder>{
    "/Home": (BuildContext context) => new ScreenHome(),
    "/Login": (BuildContext context) => new ScreenLogin()
  };

  Routes() {
    runApp(new MaterialApp(
      title: "KD 24",
      home: new ScreenSplash(),
      theme: appTheme,
      routes: routes,
    ));
  }
}
