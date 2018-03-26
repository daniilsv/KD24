import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kd24/classes/user.dart';
import 'package:kd24/components/Buttons/roundedButton.dart';
import 'package:kd24/components/TextFields/inputField.dart';
import 'package:kd24/data/database.dart';
import 'package:kd24/services/http_query.dart';
import 'package:kd24/services/validations.dart';
import 'package:kd24/theme/style.dart';


class ScreenLogin extends StatefulWidget {
  const ScreenLogin({Key key}) : super(key: key);

  @override
  ScreenLoginState createState() => new ScreenLoginState();
}

class ScreenLoginState extends State<ScreenLogin> {
  BuildContext context;
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController scrollController = new ScrollController();
  UserLoginData user = new UserLoginData();
  bool autovalidate = false;

  onPressed(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

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
      HttpQuery.executeJsonQuery("token",
          params: {
            'username': user.username,
            'password': user.password,
            'grant_type': "password"
          },
          method: "post"
      ).then((var data) {
        if (data.containsKey("error")) {
          showInSnackBar(data["error"]);
          return;
        }
        var _userData = new User.fromJson(data);
        DataBase.getInstance().then((DataBase db) {
          db.updateOrInsert("config", "key='username'", {
            "key": "username",
            "value": user.username,
          });
          db.updateOrInsert("config", "key='token'", {
            "key": "token",
            "value": _userData.token,
          });
          db.updateOrInsert("config", "key='token_type'", {
            "key": "token_type",
            "value": _userData.tokenType,
          });
          db.updateOrInsert("config", "key='token_expires'", {
            "key": "token_expires",
            "value": _userData.tokenExpires +
                new DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
        });
        User.localUser = _userData;
        Navigator.pushReplacementNamed(context, "/Home");
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    UserLoginData.fromDataBase().then((UserLoginData _user) {
      user = _user;
    });
    this.context = context;
    final Size screenSize = MediaQuery
        .of(context)
        .size;
    return new Scaffold(
      key: _scaffoldKey,
      body: new SingleChildScrollView(
        controller: scrollController,
        child: new Container(
          padding: new EdgeInsets.all(16.0),
          child: new Column(
            children: <Widget>[
              new Container(
                height: screenSize.height / 2,
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
                              initialText: user.username ?? '',
                              obscureText: false,
                              textInputType: TextInputType.text,
                              textStyle: textStyle,
                              textFieldColor: textFieldColor,
                              icon: Icons.mail_outline,
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
                              icon: Icons.lock_open,
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
