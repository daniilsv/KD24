import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Buttons/roundedButton.dart';
import 'package:shop_spy/components/TextFields/inputField.dart';
import 'package:shop_spy/data/database.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/utils.dart';
import 'package:shop_spy/services/validations.dart';
import 'package:shop_spy/theme/style.dart';

class ScreenProductAdd extends StatefulWidget {
  ScreenProductAdd({Key key, this.shopId, this.category, this.phrase}) : super(key: key);

  final int shopId;
  final String category;
  final String phrase;

  @override
  ScreenProductAddState createState() => new ScreenProductAddState();
}

class ScreenProductAddState extends State<ScreenProductAdd> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController scrollController = new ScrollController();
  bool autovalidate = false;
  Shop shop;
  Product product = new Product();

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
    }
  }

  getData() async {
    var db = new DataBase();
    Map _shop = await db.getItemById("shops", widget.shopId);
    setState(() {
      shop = new Shop.fromJson(_shop);
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  File _imageFile;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    bool isBarcode = widget.phrase != null && Utils.calcEpCode(widget.phrase);

    Widget image = new InkWell(
      onTap: () async {
        setState(() {
          _imageFile = null;
        });
        _imageFile = (await Routes.navigateTo(context, "/camera")) as File;
        setState(() {});
      },
      child: new Container(
        child: _imageFile == null
            ? new Icon(FontAwesomeIcons.camera)
            : new Stack(
          children: <Widget>[
            Utils.buildBlurredContainer(new Image.file(
              _imageFile,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            )),
            new Image.file(
              _imageFile,
              fit: BoxFit.contain,
              width: screenSize.width * 0.8,
              height: screenSize.height / 3,
              alignment: Alignment.center,
            ),
          ],
        ),
        width: screenSize.width * 0.8,
        height: screenSize.height / 3,
        decoration: new BoxDecoration(color: Colors.grey.shade200.withOpacity(0.5)),
      ),
    );

    Widget volume = new Row(
      children: <Widget>[
        const Text("Емкость"),
        new Padding(
          padding: new EdgeInsets.symmetric(horizontal: 20.0),
          child: new DropdownButton(
            onChanged: (String value) {
              setState(() {
                product.volume = value;
              });
            },
            value: product.volume ?? "Кол-во",
            items: [
              new DropdownMenuItem<String>(
                child: const Text("Вес"),
                value: "Вес",
              ),
              new DropdownMenuItem<String>(
                child: const Text("Объем"),
                value: "Объем",
              ),
              new DropdownMenuItem<String>(
                child: const Text("Кол-во"),
                value: "Кол-во",
              ),
            ],
          ),
        ),
        new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Text("Укажите"),
        ),
        new Expanded(
          child: new TextFormField(
            style: textStyle,
            keyboardType: TextInputType.number,
            validator: Validations.validateVolume,
            onSaved: (String value) {},
            decoration: new InputDecoration(
              hintText: product.volume ?? "Кол-во",
              hintStyle: hintStyle,
            ),
          ),
        ),
        new Text(product.volumeText),
      ],
    );

    Widget salePrice = new Row(
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
    );

    if (product.isSaleNew) {
      (salePrice as Row).children.add(
        new Expanded(
          child: new TextFormField(
            style: textStyle,
            keyboardType: TextInputType.number,
            validator: Validations.validatePrice,
            onSaved: (String value) {},
            decoration: new InputDecoration(
              hintText: "Sale price",
              hintStyle: hintStyle,
            ),
          ),
        ),
      );
    }

    Widget body = new Padding(
      padding: new EdgeInsets.all(8.0),
      child: new Column(
        children: <Widget>[
          new Center(child: image),
          new InputField(
              hintText: "Наименование",
              initialText: widget.phrase != null && !isBarcode ? widget.phrase : "",
              obscureText: false,
              textInputType: TextInputType.text,
              textStyle: textStyle,
              textFieldColor: textFieldColor,
              hintStyle: hintStyle,
              icon: FontAwesomeIcons.font,
              iconColor: Colors.black,
              bottomMargin: 20.0,
              onSaved: (String value) {}),
          new InputField(
              hintText: "Штрих-код",
              initialText: widget.phrase != null && isBarcode ? widget.phrase : "",
              obscureText: false,
              textInputType: TextInputType.text,
              textStyle: textStyle,
              hintStyle: hintStyle,
              textFieldColor: textFieldColor,
              icon: FontAwesomeIcons.barcode,
              iconColor: Colors.black,
              bottomMargin: 20.0,
              onSaved: (String value) {}),
          new Divider(color: Colors.black),
          volume,
          new InputField(
            hintText: "Цена",
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
          salePrice,
          new RoundedButton(
            buttonName: "Сохранить",
            onTap: () {
              _handleSubmitted();
            },
            width: screenSize.width,
            height: 50.0,
            margin: new EdgeInsets.symmetric(vertical: 10.0),
            borderWidth: 0.0,
            buttonColor: primaryColor,
          ),
        ],
      ),
    );

    Widget title = new Center(child: new CircularProgressIndicator());
    if (shop != null) {
      title = new ListTile(
        title: new Text(shop.name, style: new TextStyle(color: Colors.white)),
        subtitle: new Text(widget.category, style: new TextStyle(color: Colors.white)),
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
          constraints: new BoxConstraints(maxWidth: screenSize.width),
          padding: new EdgeInsets.all(16.0).add(new EdgeInsets.only(top: -8.0)),
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
