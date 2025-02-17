import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shop_spy/routes.dart';
import 'package:shop_spy/services/database.dart';

class Utils {
  static String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static String getDateTimeNow() {
    var now = new DateTime.now();
    return "${twoDigits(now.day)}"
        ".${twoDigits(now.month)}"
        ".${fourDigits(now.year)}"
        "T${twoDigits(now.hour)}"
        ":${twoDigits(now.minute)}"
        ":${twoDigits(now.second)}";
  }

  static showInSnackBar(GlobalKey<ScaffoldState> key, String value) {
    key.currentState.showSnackBar(new SnackBar(content: new Text(value)));
  }

  static Stack buildBlurredContainer(Widget backgroundWidget,
      {BoxConstraints constraints = const BoxConstraints.expand(), double sigma = 10.0}) {
    return new Stack(
      children: <Widget>[
        new Container(constraints: constraints, child: backgroundWidget),
        new ClipRect(
          child: new BackdropFilter(
              filter: new ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: new Stack(
                children: <Widget>[
                  new Container(
                    constraints: constraints,
                    decoration: new BoxDecoration(color: Colors.grey.shade200.withOpacity(0.1)),
                  )
                ],
              )),
        )
      ],
    );
  }

  static logout(BuildContext context) async {
    var db = new DataBase();
    db.delete("config", "token", field: "key");
    db.delete("config", "token_type", field: "key");
    db.delete("config", "token_expires", field: "key");
    db.delete("config", "username", field: "key");
    Routes.backTo(context, "/shops");
    Routes.navigateTo(context, "/login", replace: true);
  }

  static int compResult(String st1, String st2) {
    String st0;
    int i, j, k1, k2, l0, l1, l2, lmin, lminc, lm, lmm, mltot = 0, ml = 0, mp = 0, mc = 0, mpp = 0, mlp = 0;
    st1 = st1.replaceAll("\\s+", " ").toLowerCase().replaceAll("ё", "е");
    st2 = st2.replaceAll("\\s+", " ").toLowerCase().replaceAll("ё", "е");
    lmin = 3;
    l1 = st1.length;
    l2 = st2.length;
    if (l1 > l2) {
      st0 = st1;
      l0 = l1;
      st1 = st2;
      l1 = l2;
      st2 = st0;
      l2 = l0;
    }
    if (l1 < lmin) lmin = l1;
    if (l1 == 0) {
      if (l2 == 0)
        return (10100);
      else
        return (0);
    }
    mpp = 0;
    mlp = 0;
    for (i = 0; i <= l1 - lmin; i++) {
      lmm = 0;
      lminc = lmin;
      for (j = 0; j <= l2 - lminc; j++) {
        k1 = i;
        k2 = j;
        lm = 0;
        for (; (k1 < l1) && (k2 < l2); k1++, k2++) {
          if (st1[k1] == st2[k2]) //.charAt(k1)
            lm++;
          else
            break;
        }
        if (lm > lmm) lmm = lm;
        if (lminc < lmm) lminc = lmm;
      }
      if (lmm < lmin) continue;
      mc++;
      mltot += lmm;
      if (mp + ml > i) {
        if (i + lmm > mp + ml) {
          if (mp > mpp) {
            mc--;
            mltot -= ml;
            mp = mpp;
            ml = mlp;
          }
        } else {
          mc--;
          mltot -= lmm;
          continue;
        }
        if (lmm > ml) {
          mltot -= ml;
          if (i - mp < lmin)
            mc--;
          else
            mltot += i - mp;
          mp = i;
          mpp = i;
          ml = lmm;
          mlp = lmm;
        } else {
          if (i + lmm - mp - ml < lmin) {
            mc--;
            mltot -= lmm;
          } else {
            mltot -= mp + ml - i;
            mp += ml;
            ml = i + lmm - mp;
          }
        }
      } else {
        mp = i;
        ml = lmm;
        mpp = i;
        mlp = lmm;
      }
    }
    if (mltot > 0)
      return ((mltot * 100 / l1) * 100 + 140 - 8 * mc - l2 * 32 / l1).toInt();
    else
      return (0);
  }

  static bool calcEpCode(String code) {
    var s1 = 0;
    var s2 = 0;

    if (code == null || !new RegExp("^[0-9]+").hasMatch(code)) {
      return false;
    }

    if (code.length > 13) {
      return false;
    }

    if (code.length < 13) {
      for (int i = 0; i < 13 - code.length; i++) code = '0' + code;
    }

    for (var i = 1; i < code.length; i += 2) {
      s1 += int.parse(code[i - 1]);
      s2 += int.parse(code[i]);
    }

    var control = s1 + s2 * 3;
    control = 10 - control % 10;

    return control % 10 == int.parse(code[code.length - 1]);
  }
}
