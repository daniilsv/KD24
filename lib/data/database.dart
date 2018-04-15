import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shop_spy/classes/config.dart';
import 'package:sqflite/sqflite.dart';

class DataBase {
  static Database db;

  Future open() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = context.join(documentsDirectory.path, Config.dbName + ".db");
    db = await openDatabase(path, version: Config.dbVersion, onCreate: (Database db, int version) {
      db.execute('''
CREATE TABLE config ( 
  `key` text primary key not null, 
  `value` text not null)
''');
      db.execute('''
CREATE TABLE shops ( 
  `id` integer primary key, 
  `name` text not null)
''');
      db.execute('''
  CREATE TABLE products (
   `id` integer PRIMARY KEY,
   `category` text NOT NULL,
   `name` text NOT NULL,
   `brand` text DEFAULT NULL,
   `barcode` text,
   `volume` text,
   `volume_value` text,
   `image` text
);
''');
      db.execute('''
  CREATE TABLE shop_products (
   `product_id` integer NOT NULL,
   `shop_id` integer NOT NULL,
   `price` real DEFAULT NULL,
   `date` text DEFAULT NULL,
   `price_new` real DEFAULT NULL,
   `date_new` text DEFAULT NULL,
   `is_sale_new` integer DEFAULT 0,
   CONSTRAINT index_pid_shopid UNIQUE (`product_id`, `shop_id`)
);
''');
    }, onUpgrade: (Database db, int versionOld, int versionNew) {});
  }

  Future close() async => db.close();

  String _table = '';
  List<String> _select = ['i.*'];

  String _join = '';
  String _where = '';
  String _whereSeparator = 'AND';
  String _groupBy = '';
  String _orderBy = '';
  String _limit = '1000';
  int _perpage = 50;

  bool _keepFilters = false;
  bool _filterOn = false;

  DataBase select(String field, {String as}) {
    _select.add(as != null ? field + ' as `' + as + '`' : field);
    return this;
  }

  DataBase selectOnly(String field, {String as}) {
    _select = [];
    _select.add(as != null ? field + ' as `' + as + '`' : field);
    return this;
  }

  DataBase join(String tableName, as, on) {
    return this.joinInner(tableName, as, on);
  }

  DataBase joinInner(tableName, as, on) {
    _join += 'INNER JOIN ' + tableName + ' as ' + as + ' ON ' + on;
    return this;
  }

  DataBase joinLeft(tableName, as, on) {
    _join += 'LEFT OUTER JOIN ' + tableName + ' as ' + as + ' ON ' + on;
    return this;
  }

  DataBase joinCross(tableName, as) {
    _join += 'CROSS JOIN ' + tableName + ' as ' + as;
    return this;
  }

  DataBase groupBy(String field) {
    if (!field.contains("\.")) field = 'i.' + field;
    _groupBy = field;
    return this;
  }

  DataBase orderBy(String field, {String direction = 'asc'}) {
    if (field.contains("(")) {
      return this;
    }
    if (!field.contains("\.")) field = 'i.' + field;
    _orderBy = field + ' ' + direction;
    return this;
  }

  DataBase limit(int from, {int count = 0}) {
    _limit = from.toString();
    if (from < 0) {
      _limit = '0';
    }
    if (count != 0) {
      if (count <= 0) {
        count = 15;
      }
      _limit += ', ' + count.toString();
    }
    return this;
  }

  DataBase limitPage(int page, {int perpage = 0}) {
    if (perpage <= 0) {
      perpage = _perpage;
    }
    this.limit((page - 1) * perpage, count: perpage);
    return this;
  }

  DataBase limitPagePlus(int page, {int perpage = 0}) {
    if (perpage <= 0) {
      perpage = _perpage;
    }
    this.limit((page - 1) * perpage, count: perpage + 1);
    return this;
  }

  DataBase setPerPage(perpage) {
    _perpage = perpage;
    return this;
  }

  DataBase lockFilters() {
    _keepFilters = true;
    return this;
  }

  DataBase unlockFilters() {
    _keepFilters = false;
    return this;
  }

  DataBase resetFilters() {
    _select = ['i.*'];
    _groupBy = '';
    _orderBy = '';
    _limit = '';
    _join = '';
    if (_keepFilters) {
      return this;
    }
    _filterOn = false;
    _where = '';
    return this;
  }

  DataBase filter(String condition) {
    if (_filterOn) {
      _where += ' ' + _whereSeparator + ' (' + condition + ')';
    } else {
      _where += '(' + condition + ')';
      _filterOn = true;
    }
    _whereSeparator = ' AND ';
    return this;
  }

  DataBase filterStart() {
    if (_filterOn) {
      _where += ' ' + _whereSeparator + ' (';
    } else {
      _where += '(';
    }
    _filterOn = false;
    return this;
  }

  DataBase filterEnd() {
    _where += ' ) ';
    return this;
  }

  DataBase filterAnd() {
    _whereSeparator = ' AND ';
    return this;
  }

  DataBase filterOr() {
    _whereSeparator = ' OR ';
    return this;
  }

  DataBase filterNotNull(field) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter(field + ' IS NOT NULL');
    return this;
  }

  DataBase filterIsNull(String field) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter(field + ' IS NULL');
    return this;
  }

  DataBase filterEqual(String field, value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    if (value == null) {
      this.filter(field + ' IS NULL');
    } else {
      this.filter("$field = '${value.toString()}'");
    }
    return this;
  }

  DataBase filterNotEqual(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    if (value == null) {
      this.filter(field + ' IS NOT NULL');
    } else {
      this.filter("$field <> '$value'");
    }
    return this;
  }

  DataBase filterGt(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field > '$value'");
    return this;
  }

  DataBase filterLt(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field < '$value'");
    return this;
  }

  DataBase filterGtEqual(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field >= '$value'");
    return this;
  }

  DataBase filterLtEqual(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field <= '$value'");
    return this;
  }

  DataBase filterLike(String field, String value) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field LIKE '$value'");
    return this;
  }

  DataBase filterBetween(String field, String start, String end) {
    if (!field.contains("\.")) field = 'i.`$field`';
    this.filter("$field BETWEEN '$start' AND '$end'");
    return this;
  }

  String getSQL() {
    String select = _select.join(", ");
    String sql = "SELECT $select FROM $_table i ";
    if (_join.length > 0) {
      sql += _join + " ";
    }
    if (_where.length > 0) {
      sql += 'WHERE ' + _where + " ";
    }
    if (_groupBy.length > 0) {
      sql += 'GROUP BY ' + _groupBy + " ";
    }
    if (_orderBy.length > 0) {
      sql += 'ORDER BY ' + _orderBy + " ";
    }
    if (_limit.length > 0) {
      sql += 'LIMIT ' + _limit;
    }
    return sql;
  }

  Future<dynamic> getField(String table, String rowId, String field, {String filterField = 'id'}) {
    this.filterEqual(filterField, rowId);
    return this.getFieldFiltered(table, field);
  }

  Future<dynamic> getFieldFiltered(String table, String field) async {
    _select = ['i.' + field + ' as ' + field];
    _table = table;
    this.limit(1);
    String sql = this.getSQL();
    this.resetFilters();
    List<Map> result = await db.rawQuery(sql);
    if (result.length == 0) return null;

    return result[0][field];
  }

  Future<T> getItem<T>(String table, {T callback(Map<String, dynamic> item)}) async {
    _table = table;
    this.limit(1);
    String sql = this.getSQL();

    this.resetFilters();
    List<Map> result = await db.rawQuery(sql);
    if (result.length == 0) return null;
    Map item = result[0];
    if (callback != null) return callback(item);
    return item as T;
  }

  Future<T> getItemById<T>(String table, int id, {T callback(Map<String, dynamic> item)}) {
    this.filterEqual('id', id);
    return this.getItem<T>(table, callback: callback);
  }

  Future<T> getItemByField<T>(String table, String field, value, {T callback(Map<String, dynamic> item)}) {
    this.filterEqual(field, value);
    return this.getItem<T>(table, callback: callback);
  }

  Future<List<T>> get<T>(String table, {T callback(Map<String, dynamic> item)}) async {
    _table = table;
    String sql = this.getSQL();
    this.resetFilters();
    List<Map> result = await db.rawQuery(sql);
    if (result.length == 0) return [];
    List<T> ret = [];
    for (Map<String, dynamic> item in result) {
      if (callback != null)
        ret.add(callback(item));
      else
        ret.add(item as T);
    }
    return ret;
  }

  Future<int> delete(String table, value, {String field = 'id'}) {
    this.filterEqual(field, value);
    return this.deleteFiltered(table);
  }

  Future<int> deleteFiltered(table) {
    String where = _where;
    this.resetFilters();

    String sql = "DELETE FROM $table WHERE $where;";
    return db.rawDelete(sql);
  }

  Future<int> update(String table, value, Map<String, dynamic> data, {String field = 'id'}) {
    this.filterEqual(field, value);
    return this.updateFiltered(table, data);
  }

  Future<int> updateFiltered(String table, Map<String, dynamic> data) {
    String where = _where;
    this.resetFilters();
    List keys = data.keys.map((var l) => "`$l`=?").toList();
    String sql = "UPDATE $table SET ${keys.join(",")} WHERE ${where.replaceAll("i\.", "")};";
    print(sql);
    return db.rawUpdate(sql, data.values.toList());
  }

  Future insertList(String table, List<Map<String, dynamic>> dataset) async {
    List keys = dataset.first.keys.map((var l) => "`$l`").toList();
    List vals = keys.map((var l) => "?").toList();
    String sql = "INSERT OR REPLACE INTO `$table` ( ${keys.join(",")} ) VALUES ( ${vals.join(",")} );";
    return db.transaction((txn) async {
      var batch = db.batch();
      for (Map<String, dynamic> data in dataset) {
        batch.execute(sql, data.values.toList());
      }
      await txn.applyBatch(batch);
    });
  }

  Future<int> insert(String table, Map data) async {
    return await db.insert(table, data);
  }

  Future<int> updateOrInsert(String table, Map data) async {
    List keys = data.keys.map((var l) => "`$l`").toList();
    List vals = keys.map((var l) => "?").toList();
    String sql = "INSERT OR REPLACE INTO `$table` ( ${keys.join(",")} ) VALUES ( ${vals.join(",")} );";
    return db.rawInsert(sql, data.values.toList());
  }
}
