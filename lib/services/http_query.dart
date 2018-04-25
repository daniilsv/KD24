import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shop_spy/classes/user.dart';

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
    Map<String, String> _headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "application/json"};
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
    try {
      var ret = json.decode(response.body);
      if (ret is Map) {
        if (ret.containsKey("Message")) return {"error": ret["Message"]};

        if (ret.containsKey("error_description")) return {"error": ret["error_description"]};

        if (ret.containsKey("error")) return {"error": ret["error"]};
      }
      return ret;
    } on Exception {}
    if (response.statusCode == 202) {
      return {"success": true};
    }
  }

  static Future<dynamic> sendData(String action, {Map<String, dynamic> query, dynamic params}) async {
    if (params == null) params = {};
    action = "api/" + action;

    Map<String, String> _headers = {"Content-type": "application/json", "Accept": "application/json"};
    if (User.localUser != null) {
      _headers["Authorization"] = User.localUser.tokenType + " " + User.localUser.token;
    }
    var client = new http.Client();
    http.Response response = await client.post(hrefTo(action, query: query), headers: _headers, body: params);

    try {
      var ret = json.decode(response.body);
      print(ret);
      if (ret is Map) {
        if (ret.containsKey("Message")) return {"error": ret["Message"]};

        if (ret.containsKey("error_description")) return {"error": ret["error_description"]};

        if (ret.containsKey("error")) return {"error": ret["error"]};
      }
    } on Exception {}
    if (response.statusCode == 202) {
      return {"success": true};
    }
  }
}
