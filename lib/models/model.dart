import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:sqflite/sqflite.dart';

abstract class Model {
  int? get id;
  DateTime get date;
  ModelRepository get repository;

  List<String> validate() {
    return [];
  }

  Duration get age {
    return clock.now().difference(date);
  }

  Future<bool> save() async {
    // TODO update the id of the model
    return repository.save(this);
  }

  @override
  String toString() {
    return repository.toSQLMap(this).toString();
  }
}

abstract class ModelRepository<T extends Model> {
  final String tableName;
  final String? writeTableName;
  final String idField;
  final String timestampField;

  const ModelRepository(
    this.tableName, {
    this.idField = "id",
    this.timestampField = "timestamp",
    this.writeTableName,
  });

  T fromMap(Map<String, Object?> map);
  Map<String, Object> toSQLMap(T model);

  Future<List<T>> query({
    int? after,
    int? before,
    Map<String, Object>? conditions,
    int? limit,
  }) async {
    var cdb = await CarerDB.instance;
    var (where, whereArgs) = _buildWhereStatement(
        after: after, before: before, conditions: conditions);
    var res = await cdb.db.query(tableName,
        where: where,
        whereArgs: whereArgs,
        limit: limit,
        orderBy: "$timestampField DESC");
    return res.map((e) => fromMap(e)).toList();
  }

  Future<List<T>> lastMins(int minsAgo) async {
    return (await query(
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch));
  }

  Future<bool> save(T model) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;
    if (model.id == null) {
      var ret = await cdb.db.insert(tb, toSQLMap(model),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      return ret != 0;
    } else {
      var ret = await cdb.db.update(tb, toSQLMap(model),
          where: '$idField = ?', whereArgs: [model.id]);
      return ret != 0;
    }
  }

  Future<int?> count(
      {int? after, int? before, Map<String, Object>? conditions}) async {
    var cdb = await CarerDB.instance;
    var (where, whereArgs) = _buildWhereStatement(
        after: after, before: before, conditions: conditions);

    var res = await cdb.db.query(tableName,
        columns: ['COUNT(*)'], where: where, whereArgs: whereArgs);
    return res.first.values.first as int?;
  }

  // utils
  (String?, List<Object>?) _buildWhereStatement(
      {int? after, int? before, Map<String, Object>? conditions}) {
    var where = <String>[];
    var whereArgs = <Object>[];
    if (after != null) {
      where.add('$timestampField >= ?');
      whereArgs.add(after);
    }
    if (before != null) {
      where.add('$timestampField < ?');
      whereArgs.add(before);
    }
    if (conditions != null) {
      conditions.forEach((key, value) {
        where.add('$key ');
        whereArgs.add(value);
      });
    }
    if (where.isEmpty) {
      return (null, null);
    }
    return (where.join(' AND '), whereArgs);
  }

  bool validateNotNull(Map<String, Object?> m, List<String> keys) {
    for (var key in keys) {
      if (m[key] == null) {
        return false;
      }
    }
    return true;
  }

  bool validateType(
      Map<String, Object?> m, List<String> keys, List<Type> types) {
    assert(keys.length == types.length);

    for (var i = 0; i < keys.length; i++) {
      if (m[keys[i]] == null) {
        continue; // Ignore if null
      }
      if (m[keys[i]].runtimeType != types[i]) {
        return false;
      }
    }
    return true;
  }
}
