import 'dart:async';

import 'package:sqflite/sqflite.dart';


class DataBase {
  static DataBase _instance;

  static Future<DataBase> getInstance() {
    if (_instance == null)
      _instance = new DataBase();
    return new Future(() => _instance);
  }

  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) {
        db.execute('''
create table config ( 
  `key` text primary key not null, 
  `value` text not null)
''');
        db.execute('''
create table retailers ( 
  `id` integer primary key, 
  `name` text not null)
''');
        db.execute('''
create table products ( 
  `id` integer primary key autoincrement, 
  `original_id` integer,
  `retailer_id` integer,
  `category` text not null,
  `name` text not null,  
  `brand` text not null,
  `barCode` text not null,
  `volume` text,
  `volumeValue` text,
  `image` text,
  `price` real,
  `price_new` real
  )
''');
      },
      onUpgrade: (Database db, int versionOld, int versionNew) {
        if (versionNew == 2) {}
      },
    );
  }

  Future<int> insert(String table, Map data) async {
    return await db.insert(table, data);
  }

  Future<int> update(String table, String where, Map data) async {
    return await db.update(table, data, where: where);
  }

  Future<int> updateOrInsert(String table, String where, Map data) async {
    var row = await getRow(table, where);
    if (row == null)
      return await insert(table, data);
    else
      return await update(table, where, data);
  }

  Future<List<Map>> getRows(String table,
      {String where, String order, String group}) async {
    List<Map> ret = await db.query(
        table, where: where, orderBy: order, groupBy: group);
    if (ret.length > 0) {
      return ret;
    }
    return [];
  }

  Future<Map> getRow(String table, String where) async {
    List<Map> ret = await db.query(table, where: where, limit: 1);
    if (ret.length > 0) {
      return ret.first;
    }
    return null;
  }

  Future<dynamic> getField(String table, String where, String field) async {
    var row = await db.query(table, where: where, limit: 1);
    if (row.length > 0) {
      return row.first[field];
    }
  }

  Future<int> delete(String table, String where) async {
    return await db.delete(table, where: where);
  }


  Future close() async => db.close();

}