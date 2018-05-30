import 'dart:convert';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shop_spy/classes/product.dart';
import 'package:shop_spy/classes/shop.dart';
import 'package:shop_spy/components/Buttons/roundedButton.dart';
import 'package:shop_spy/components/TextFields/inputField.dart';
import 'package:shop_spy/services/database.dart';
import 'package:shop_spy/services/http_query.dart';
import 'package:shop_spy/services/utils.dart';
import 'package:shop_spy/services/validations.dart';

class ScreenProductAdd extends StatefulWidget {
  ScreenProductAdd({Key key, this.shopId, this.phrase}) : super(key: key);

  final int shopId;
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

  TextEditingController barcodeController;

  _handleSubmitted() async {
    FormState form = formKey.currentState;
    if (!form.validate()) {
      autovalidate = true;
      Utils.showInSnackBar(_scaffoldKey, 'Please fix the errors in red before submitting.');
    } else {
      form.save();
      Navigator.of(context).push(new MaterialPageRoute(
          builder: (_) => new UploadWidget(
                product: product,
                image: _imageFile,
                shopId: widget.shopId,
              )));
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
    phraseIsBarcode = widget.phrase != null && Utils.calcEpCode(widget.phrase);
    barcodeController = new TextEditingController(text: widget.phrase != null && phraseIsBarcode ? widget.phrase : "");
  }

  bool phraseIsBarcode;
  File _imageFile;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    FloatingActionButton galleryPick = new FloatingActionButton(
      heroTag: "0",
      child: const Icon(FontAwesomeIcons.images),
      onPressed: () async {
        _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
        setState(() {});
      },
    );
    FloatingActionButton cameraPick = new FloatingActionButton(
      heroTag: "1",
      child: const Icon(FontAwesomeIcons.camera),
      onPressed: () async {
        _imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
        setState(() {});
      },
    );
    Widget image = new Container(
      child: _imageFile == null
          ? new Center(
              child: new Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  galleryPick,
                  new Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: cameraPick,
                  ),
                ],
              ),
            )
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
                new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        galleryPick,
                        new Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: cameraPick,
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
      width: screenSize.width * 0.8,
      height: screenSize.height / 3,
      decoration: new BoxDecoration(color: Colors.grey.shade200.withOpacity(0.5)),
    );

    Widget salePrice = new Row(
      children: <Widget>[
        new InkWell(
          child: const Text("Акционная цена"),
          onTap: () {
            setState(() {
              product.isSaleNew = !product.isSaleNew;
            });
          },
        ),
        new Checkbox(
          onChanged: (bool value) {
            setState(() {
              product.isSaleNew = value;
            });
          },
          activeColor: Colors.orangeAccent,
          value: product.isSaleNew,
        )
      ],
    );

    if (product.isSaleNew) {
      (salePrice as Row).children.add(
            new Expanded(
              child: new TextFormField(
                keyboardType: TextInputType.number,
                validator: Validations.validatePrice,
                onSaved: (String value) {
                  product.priceNew = double.parse(value);
                },
                decoration: new InputDecoration(
                  hintText: "Sale price",
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
              initialText: "",
              obscureText: false,
              textInputType: TextInputType.text,
              validateFunction: Validations.validateTitle,
              icon: FontAwesomeIcons.font,
              iconColor: Colors.black,
              bottomMargin: 20.0,
              onSaved: (String value) {
                product.name = value;
              }),
          new DecoratedBox(
            decoration: new BoxDecoration(borderRadius: new BorderRadius.all(new Radius.circular(30.0))),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new TextFormField(
                    keyboardType: TextInputType.number,
                    validator: Validations.validateBarcode,
                    controller: barcodeController,
                    onSaved: (String value) {
                      product.barcode = value;
                    },
                    decoration: new InputDecoration(
                      hintText: "Штрих-код",
                      icon: new Icon(FontAwesomeIcons.barcode),
                    ),
                  ),
                ),
                new IconButton(icon: new Icon(Icons.photo_camera), onPressed: () => scan())
              ],
            ),
          ),
          new Divider(color: Colors.black),
          new Row(
            children: <Widget>[
              new InkWell(
                child: const Text("Штрих-код назначен магазином"),
                onTap: () {
                  setState(() {
                    product.isRetailerPackage = !product.isRetailerPackage;
                  });
                },
              ),
              new Checkbox(
                onChanged: (bool value) {
                  setState(() {
                    product.isRetailerPackage = value;
                  });
                },
                activeColor: Colors.orangeAccent,
                value: product.isRetailerPackage,
              ),
            ],
          ),
          new Row(
            children: <Widget>[
              new InkWell(
                child: const Text("Весовой"),
                onTap: () {
                  setState(() {
                    product.isWeight = !product.isWeight;
                  });
                },
              ),
              new Checkbox(
                onChanged: (bool value) {
                  setState(() {
                    product.isWeight = value;
                  });
                },
                activeColor: Colors.orangeAccent,
                value: product.isWeight,
              ),
            ],
          ),
          new Row(
            children: <Widget>[
              new InkWell(
                child: const Text("Упакованный"),
                onTap: () {
                  setState(() {
                    product.isPackage = !product.isPackage;
                  });
                },
              ),
              new Checkbox(
                onChanged: (bool value) {
                  setState(() {
                    product.isPackage = value;
                  });
                },
                activeColor: Colors.orangeAccent,
                value: product.isPackage,
              ),
            ],
          ),
          new Row(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: const Text("Вес"),
              ),
              new Expanded(
                child: new TextFormField(
                  keyboardType: TextInputType.number,
                  validator: Validations.validateVolumeValue,
                  onSaved: (String value) {
                    product.volumeValue = value;
                  },
                  decoration: new InputDecoration(
                    hintText: "Кг",
                  ),
                ),
              )
            ],
          ),
          new InputField(
            hintText: "Цена",
            obscureText: false,
            initialText: "",
            textInputType: TextInputType.number,
            validateFunction: Validations.validatePrice,
            icon: FontAwesomeIcons.rubleSign,
            iconColor: Colors.black,
            bottomMargin: 20.0,
            onSaved: (String price) {
              product.price = double.parse(price);
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
          ),
        ],
      ),
    );

    Widget title = new Center(child: new CircularProgressIndicator());
    if (shop != null) {
      title = new Text(shop.name, style: new TextStyle(color: Colors.white));
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

  void scan() {
    try {
      BarcodeScanner.scan().then((String _) {
        setState(() {
          barcodeController.text = _;
        });
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
      } else {}
    } on FormatException {} catch (e) {}
  }
}

class UploadWidget extends StatefulWidget {
  final int shopId;

  final Product product;

  final File image;

  UploadWidget({Key key, this.product, this.image, this.shopId}) : super(key: key);

  @override
  _UploadWidgetState createState() => new _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Center(
            child: new Column(
      children: <Widget>[new Text("Загружаем новый товар"), new CircularProgressIndicator()],
    )));
  }

  @override
  void initState() {
    uploadData();
    super.initState();
  }

  void uploadData() async {
    if (widget.image != null) {
      widget.image.readAsBytes().then((List<int> bytes) {
        img.Image image = img.decodeImage(bytes);
        img.Image thumbnail = img.copyResize(image, image.width * 512 ~/ image.height, 512);
        HttpQuery.sendData("ImagesUpload", params: base64.encode(thumbnail.getBytes()), query: {
          "name": "${widget.product.barcode}.${widget.image.path
              .split(".")
              .last}"
        });
      });
    }

    var ret = await HttpQuery.sendData("Products/SendTodayCheckProduct", params: [
      {
        "barCode": widget.product.barcode,
        "retailerId": widget.shopId,
        "name": widget.product.name,
        "price0": widget.product.price,
        "price1": widget.product.priceNew,
        "date": Utils.getDateTimeNow(),
        "isWeight": widget.product.isWeight,
        "isPackage": widget.product.isPackage,
        "weightPack": widget.product.volumeValue,
        "isPackRetailer": widget.product.isRetailerPackage
      }
    ]);
    if (ret is List && ret[0] is Map && ret[0]['id'] is num) {
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }
}
