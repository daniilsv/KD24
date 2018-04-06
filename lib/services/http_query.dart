import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kd24_shop_spy/classes/user.dart';
import 'package:path/path.dart';

class HttpQuery {
  static final String protocol = "http";
  static final String baseUrl = "prodbasewebapi.azurewebsites.net";

//  static final String protocol = "http";
//  static final String baseUrl = "kolushkin.dlinkddns.com";

  static String hrefTo(String path, {String protocol, String baseUrl, String file, Map query}) {
    return new Uri(
        scheme: protocol ?? HttpQuery.protocol,
        host: baseUrl ?? HttpQuery.baseUrl,
        path: join(path, file),
        queryParameters: query)
        .toString();
  }

  static Future<dynamic> executeJsonQuery(String action, {Map<String, dynamic> params, String method = "get"}) async {
    if (params == null) params = {};
    action = "api/" + action;
    Map _headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "application/json"};
    if (User.localUser != null) {
      _headers["Authorization"] = User.localUser.tokenType + " " + User.localUser.token;
    }
    http.Response response;
    if (method == "post") {
      response = await http.post(hrefTo(action), body: params, headers: _headers);
    } else if (method == "get") {
      response = await http.get(
        hrefTo(action, query: params),
        headers: _headers,
      );
    }
    var ret = {};
    try {
      ret = json.decode(response.body);

      if (ret is Map) {
        if (ret.containsKey("Message")) return {"error": ret["Message"]};

        if (ret.containsKey("error_description")) return {"error": ret["error_description"]};

        if (ret.containsKey("error")) return {"error": ret["error"]};
      }
    } on Exception {}
    if (response.statusCode == 202) {
      ret = {"success": true};
    }

    return ret;
  }

  static Future<dynamic> sendData(String action, {dynamic params}) async {
    if (params == null) params = {};
    action = "api/" + action;

    Map _headers = {"Content-type": "application/json", "Accept": "application/json"};
    if (User.localUser != null) {
      _headers["Authorization"] = User.localUser.tokenType + " " + User.localUser.token;
    }
    var client = new http.Client();
    http.Response response = await client.post(hrefTo(action), headers: _headers, body: params);
    var ret = {};
    try {
      ret = json.decode(response.body);

      if (ret is Map) {
        if (ret.containsKey("Message")) return {"error": ret["Message"]};

        if (ret.containsKey("error_description")) return {"error": ret["error_description"]};

        if (ret.containsKey("error")) return {"error": ret["error"]};
      }
    } on Exception {}
    if (response.statusCode == 202) {
      ret = {"success": true};
    }

    return ret;
  }
}
