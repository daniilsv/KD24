import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/components/networkimage/flutter_advanced_networkimage.dart';
import 'package:shop_spy/services/http_query.dart';

typedef void OpenProductCallback(int productId);

class ProductsList extends StatelessWidget {
  const ProductsList({this.products, this.openProduct, this.isLoading});

  final List<Product> products;
  final OpenProductCallback openProduct;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return new Center(child: new CircularProgressIndicator());

    if (products.length == 0) {
      return new Center(child: const Text("Нет товаров по этой выборке"));
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        Product product = products[index];
        return new Row(children: [
          new Expanded(
              child: new Card(
            child: new MaterialButton(
              child: new Column(children: <Widget>[
                new ListTile(
                  title: new Text(product.name),
                  subtitle: new Text(product.barcode, style: new TextStyle(fontSize: 16.0)),
                  leading: new Image(
                    image: new AdvancedNetworkImage(
                        HttpQuery.hrefTo("prodbasecontent/Images",
                            baseUrl: "prodbasestorage.blob.core.windows.net", file: product.image),
                        useDiskCache: true),
                    fit: BoxFit.contain,
                    height: 80.0,
                    width: 40.0,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                new Row(
                  children: <Widget>[
                    product.price != null
                        ? new Text(product.price.toString() ?? "", style: new TextStyle(color: Colors.grey))
                        : const Text(""),
                    product.price != null ? new Icon(FontAwesomeIcons.arrowRight, size: 12.0) : const Text(""),
                    product.priceNew == null
                        ? const Icon(FontAwesomeIcons.times, color: Colors.red)
                        : new Text(product.priceNew.toString() ?? "", style: new TextStyle(color: Colors.green)),
                    new Padding(
                        padding: new EdgeInsets.only(left: 10.0),
                        child: new Text("за ${product.volumeValue} ${product.volumeText}")),
                    product.priceNew != null && product.isSaleNew ? const Icon(FontAwesomeIcons.star) : const Text(""),
                  ],
                ),
                new Padding(
                  padding: new EdgeInsets.only(top: 5.0),
                )
              ]),
              onPressed: () => openProduct(product.id),
            ),
          ))
        ]);
      },
    );
  }
}
