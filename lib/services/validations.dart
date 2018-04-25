import 'package:shop_spy/services/utils.dart';

class Validations {
  static String validatePrice(String value) {
    if (value.isEmpty) return 'Price is required.';
    final RegExp nameExp = new RegExp(r'^[0-9\.]+$');
    if (!nameExp.hasMatch(value)) return 'Please enter only digits characters.';
    return null;
  }

  static String validateVolumeValue(String value) {
    if (value.isEmpty) return 'Volume is required.';
    final RegExp nameExp = new RegExp(r'^[0-9\.]+$');
    if (!nameExp.hasMatch(value)) return 'Please enter only digits characters.';
    return null;
  }

  static String validateUsername(String value) {
    if (value.isEmpty) return 'Login is required.';
    final RegExp nameExp = new RegExp(r'^[A-za-z ]+$');
    if (!nameExp.hasMatch(value)) return 'Invalid login';
    return null;
  }

  static String validatePassword(String value) {
    if (value.isEmpty) return 'Please choose a password.';
    return null;
  }

  static String validateBarcode(String value) {
    return !Utils.calcEpCode(value) ? "Invalid barcode" : null;
  }

  static String validateTitle(String value) {
    if (value.isEmpty) return 'Title is required.';
    return null;
  }
}
