import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/classes/config.dart';
import 'package:kd24_shop_spy/classes/user.dart';
import 'package:kd24_shop_spy/components/Buttons/roundedButton.dart';
import 'package:kd24_shop_spy/theme/style.dart';

class ScreenSettings extends StatefulWidget {
  const ScreenSettings({Key key}) : super(key: key);

  @override
  ScreenSettingsState createState() => new ScreenSettingsState();
}

class ScreenSettingsState extends State<ScreenSettings> {
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
    FormState form = formKey.currentState;
    form.save();
    Config.saveToDB();
    Navigator.pop(context);
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
                          new Row(
                            children: <Widget>[
                              new Checkbox(
                                value: Config.moveDownDone,
                                onChanged: (bool val) {
                                  setState(() => Config.moveDownDone = val);
                                },
                              ),
                              new Text("Скрывать обработанные")
                            ],
                          ),
                          new RoundedButton(
                            buttonName: "Сохранить",
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
