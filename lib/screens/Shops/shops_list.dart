import 'package:flutter/material.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/routes.dart';

class ShopsList extends StatelessWidget {
  const ShopsList({this.shops});

  final List<Shop> shops;

  @override
  Widget build(BuildContext context) {
    if (shops.length == 0) {
      return new Center(child: new CircularProgressIndicator());
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: shops.length,
      itemBuilder: (BuildContext context, int index) {
        var shop = shops[index];
        return new Row(children: [
          new Expanded(
            child: new Card(
              child: new MaterialButton(
                  height: 50.0,
                  child: new ListTile(
                    title: new Text(
                      shop.name,
                      style: new TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onPressed: () => Routes.navigateTo(context, "/shop/${shop.id}")),
            ),
          )
        ]);
      },
    );
  }
}
