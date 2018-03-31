import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kd24_shop_spy/classes/product.dart';
import 'package:kd24_shop_spy/classes/shop.dart';
import 'package:kd24_shop_spy/classes/user.dart';
import 'package:kd24_shop_spy/components/Buttons/roundedButton.dart';
import 'package:kd24_shop_spy/components/TextFields/inputField.dart';
import 'package:kd24_shop_spy/services/validations.dart';
import 'package:kd24_shop_spy/theme/style.dart';

class ScreenProduct extends StatefulWidget {
  ScreenProduct({Key key, String id}) : super(key: key) {
    this.id = int.parse(id);
  }

  int id;
  Shop shop;
  Product product;

  @override
  ScreenProductState createState() => new ScreenProductState();
}

class ScreenProductState extends State<ScreenProduct> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController scrollController = new ScrollController();
  UserLoginData user = new UserLoginData();
  bool autovalidate = false;

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _handleSubmitted() {
    final FormState form = formKey.currentState;
    if (!form.validate()) {
      autovalidate = true;
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      key: _scaffoldKey,
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
                  children: <Widget>[
                    new Form(
                      key: formKey,
                      autovalidate: autovalidate,
                      child: new Column(
                        children: <Widget>[
                          new InputField(
                              hintText: "Username",
                              obscureText: false,
                              textInputType: TextInputType.text,
                              textStyle: textStyle,
                              textFieldColor: textFieldColor,
                              icon: Icons.account_circle,
                              iconColor: Colors.black,
                              bottomMargin: 20.0,
                              validateFunction: Validations.validateUsername,
                              onSaved: (String username) {
                                user.username = username;
                              }),
                          new InputField(
                              hintText: "Password",
                              obscureText: true,
                              textInputType: TextInputType.text,
                              textStyle: textStyle,
                              textFieldColor: textFieldColor,
                              icon: Icons.lock,
                              iconColor: Colors.black,
                              bottomMargin: 30.0,
                              validateFunction: Validations.validatePassword,
                              onSaved: (String password) {
                                user.password = password;
                              }),
                          new RoundedButton(
                            buttonName: "Sign in",
                            onTap: _handleSubmitted,
                            width: screenSize.width,
                            height: 50.0,
                            bottomMargin: 10.0,
                            borderWidth: 0.0,
                            buttonColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
