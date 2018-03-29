import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/screens/Splash/index.dart';
import 'package:kd24_shop_spy/theme/style.dart';

void main() {
  Routes.initRoutes();
  runApp(new MaterialApp(
      title: "KD 24", home: new ScreenSplash(), theme: appTheme));
}
