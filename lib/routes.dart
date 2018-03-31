import 'dart:async';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/screens/Categories/index.dart';
import 'package:kd24_shop_spy/screens/Login/index.dart';
import 'package:kd24_shop_spy/screens/Product/index.dart';
import 'package:kd24_shop_spy/screens/Products/index.dart';
import 'package:kd24_shop_spy/screens/Settings/index.dart';
import 'package:kd24_shop_spy/screens/Shops/index.dart';

class Routes {
  static final Router _router = new Router();

  static void initRoutes() {
    _router.define("/login",
        handler: new Handler(
            handlerFunc: (BuildContext context, Map<String, dynamic> params) =>
            new ScreenLogin()));

    _router.define("/settings",
        handler: new Handler(
            handlerFunc: (BuildContext context, Map<String, dynamic> params) =>
            new ScreenSettings()));

    _router.define("/shops",
        handler: new Handler(
            handlerFunc: (BuildContext context, Map<String, dynamic> params) =>
            new ScreenShops()));

    _router.define("/shop/:id", handler: new Handler(
        handlerFunc: (BuildContext context, Map<String, dynamic> params) {
          return new ScreenCategories(shopId: int.parse(params["id"][0]));
        }));

    _router.define("/shop/:shop_id/:category", handler: new Handler(
        handlerFunc: (BuildContext context, Map<String, dynamic> params) {
          return new ScreenProducts(
              shopId: int.parse(params["shop_id"][0]),
              category: params["category"][0]);
        }));

    _router.define("/shop/:shop_id/:category/:id", handler: new Handler(
        handlerFunc: (BuildContext context, Map<String, dynamic> params) {
          return new ScreenProduct(
              shopId: int.parse(params["shop_id"][0]),
              category: params["category"][0],
              id: int.parse(params["id"][0]));
        }));

//    _router.define("/shop/:shop_id/:category/add/:barcode", handler: new Handler(
//        handlerFunc: (BuildContext context, Map<String, dynamic> params) {
//      return new ScreenProductAdd(barcode: params["barcode"][0]);
//    }));
  }

  static Future<dynamic> navigateTo(BuildContext context, String route,
      {TransitionType transition = TransitionType.inFromRight,
        bool replace = false}) {
    return _router.navigateTo(context, route,
        replace: replace, transition: transition);
  }

  static void backTo(BuildContext context, String path) {
    Navigator.of(context).popUntil((Route<dynamic> route) {
      return route == null ||
          route is ModalRoute && route.settings.name == path;
    });
  }
}
