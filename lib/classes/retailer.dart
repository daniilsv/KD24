import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Retailer {
  int id;
  String name;
  bool isVisible;
  bool isVisibleApk;

  Retailer({this.id, this.name, this.isVisible, this.isVisibleApk});

  factory Retailer.fromJson(Map<String, dynamic> json) =>
      new Retailer(
        id: json['id'],
        name: json['name'] as String,
        isVisible: json['isVisible'] as bool,
        isVisibleApk: json['isVisibleApk'] as bool,
      );

}
