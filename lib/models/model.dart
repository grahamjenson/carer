import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';
import 'package:sqflite/sqflite.dart';

abstract class Model {
  int? get id;
  DateTime get date;
  ModelRepository get repository;

  // List<String> validate();

  Duration get age {
    return clock.now().difference(date);
  }

  Future<bool> save() async {
    return repository.save(this);
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
    int after = 0,
    int before = 9999999999999999,
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
      {int after = 0,
      int before = 9999999999999999,
      Map<String, Object>? conditions}) async {
    var cdb = await CarerDB.instance;
    var (where, whereArgs) = _buildWhereStatement(
        after: after, before: before, conditions: conditions);

    var res = await cdb.db.query(tableName,
        columns: ['COUNT(*)'], where: where, whereArgs: whereArgs);
    return res.first.values.first as int?;
  }

  // utils
  (String, List<Object>) _buildWhereStatement(
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
    return (where.join(' AND '), whereArgs);
  }
}
