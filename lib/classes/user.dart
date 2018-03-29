import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:kd24_shop_spy/data/database.dart';

@JsonSerializable()
class UserLoginData {
  String username;
  String password;

  UserLoginData({this.username = "", this.password = ""});

  static Future<UserLoginData> fromDataBase() async {
    DataBase db = await DataBase.getInstance();
    return new UserLoginData(
      username: await db.getField("config", "key='username'", "value") ?? "",
      password: null,
    );
  }
}

@JsonSerializable()
class User {
  String token;
  String tokenType;
  int tokenExpires;
  String error;

  User({this.token, this.tokenType, this.tokenExpires});

  factory User.fromJson(Map<String, dynamic> json) =>
      new User(
        token: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        tokenExpires: json['expires_in'] as int,
      );

  static User localUser;

  static Future<User> fromDataBase() async {
    DataBase db = await DataBase.getInstance();
    return new User(
        token: await db.getField("config", "key='token'", "value"),
        tokenType: await db.getField("config", "key='token_type'", "value"),
        tokenExpires: int.parse(
            await db.getField("config", "key='token_expires'", "value") ??
                "0"));
  }
}
