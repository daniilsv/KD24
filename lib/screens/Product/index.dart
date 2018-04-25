import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Buttons/roundedButton.dart';
import 'package:shop_spy/components/TextFields/inputField.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';
import 'package:shop_spy/services/utils.dart';
import 'package:shop_spy/services/validations.dart';
import 'package:shop_spy/theme/style.dart';

class ScreenProduct extends StatefulWidget {
  ScreenProduct({Key key, this.shopId, this.id}) : super(key: key);

  final int shopId;
  final int id;

  @override
  ScreenProductState createState() => new ScreenProductState();
}

class ScreenProductState extends State<ScreenProduct> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Product product = new Product();
  ScrollController scrollController = new ScrollController();
  bool autovalidate = false;
  Shop shop;

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _handleSubmitted() async {
    FormState form = formKey.currentState;
    if (!form.validate()) {
      autovalidate = true;
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      product.dateNew = Utils.getDateTimeNow();
      var db = new DataBase();
      await db.filterEqual("product_id", product.id).filterEqual("shop_id", widget.shopId).updateFiltered(
          "shop_products",
          {"is_sale_new": product.isSaleNew ? 1 : 0, "price_new": product.priceNew, "date_new": product.dateNew});
      Navigator.pop(context, product);
    }
  }

  getData() async {
    var db = new DataBase();
    shop = await db.getItemById<Shop>("shops", widget.shopId, callback: (_) => new Shop.fromJson(_));
    product = await db
        .select("p.*")
        .joinLeft("products", "p", "p.id=i.product_id")
        .filterEqual("i.shop_id", widget.shopId)
        .filterEqual("i.product_id", widget.id)
        .getItem<Product>("shop_products", callback: (_) => new Product.fromJson(_));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    Widget body = new Center(child: new CircularProgressIndicator());

    if (product != null)
      body = new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: <Widget>[
            new Center(
              child: new Image(
                image: new AdvancedNetworkImage(
                    HttpQuery.hrefTo("prodbasecontent/Images",
                        baseUrl: "prodbasestorage.blob.core.windows.net", file: product.image),
                    useDiskCache: true),
                fit: BoxFit.contain,
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                height: MediaQuery
                    .of(context)
                    .size
                    .height / 3,
                alignment: Alignment.center,
              ),
            ),
            new ListTile(
              title: new Text(product.name),
              subtitle: new Text(product.barcode, style: new TextStyle(fontSize: 16.0)),
            ),
            new Divider(color: Colors.black),
            new Row(
              children: <Widget>[
                const Text("Цена за"),
                new Padding(padding: new EdgeInsets.only(left: 20.0), child: new Text(product.volumeValue)),
                new Padding(padding: new EdgeInsets.only(left: 20.0), child: new Text(product.volumeText))
              ],
            ),
            product.price != null
                ? new Row(
              children: <Widget>[
                const Text("Старая цена: "),
                new Padding(
                  padding: new EdgeInsets.only(left: 20.0),
                  child: new Text(product.price.toString()),
                )
              ],
            )
                : const Text(""),
            new InputField(
              hintText: "Price",
              obscureText: false,
              initialText: "",
              textInputType: TextInputType.number,
              textStyle: textStyle,
              validateFunction: Validations.validatePrice,
              textFieldColor: textFieldColor,
              icon: FontAwesomeIcons.rubleSign,
              iconColor: Colors.black,
              bottomMargin: 20.0,
              onSaved: (String price) {
                product.priceNew = double.parse(price);
              },
            ),
            new Row(
              children: <Widget>[
                const Text("Акционная цена"),
                new Checkbox(
                    onChanged: (bool value) {
                      setState(() {
                        product.isSaleNew = value;
                      });
                    },
                    activeColor: Colors.orangeAccent,
                    value: product.isSaleNew)
              ],
            ),
            new RoundedButton(
              buttonName: "Сохранить",
              onTap: () {
                _handleSubmitted();
              },
              width: screenSize.width,
              height: 50.0,
              bottomMargin: 10.0,
              borderWidth: 0.0,
              buttonColor: primaryColor,
            ),
            product.priceNew != null
                ? product.dateNew == null
                ? new Text("Выгружено: ${product.price}", style: new TextStyle(color: Colors.green))
                : new Text("Не выгружено: ${product.priceNew}", style: new TextStyle(color: Colors.red))
                : const Text("")
          ],
        ),
      );
    Widget title = new Center(child: new CircularProgressIndicator());
    if (shop != null) {
      title = new ListTile(
        title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
        subtitle: new Text(product.category, style: new TextStyle(color: Colors.white)),
      );
    }
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: title,
        backgroundColor: Colors.orange,
      ),
      body: new SingleChildScrollView(
        controller: scrollController,
        child: new Container(
          padding: new EdgeInsets.all(16.0),
          child: new Column(
            children: <Widget>[
              new Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[new Form(key: formKey, autovalidate: autovalidate, child: body)],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
