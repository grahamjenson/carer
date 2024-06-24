import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sqflite/sqflite.dart';

abstract class Model {
  int? get id;
  set id(int? id);

  DateTime get date;
  ModelRepository get repository;

  Duration get age {
    return clock.now().difference(date);
  }

  Future<bool> save() {
    return futureProfile("$runtimeType save", repository.save(this));
  }

  Future<bool> upsert() {
    return futureProfile(
        "$runtimeType upsert", repository.upsert(this, uniqueValues()));
  }

  List<String> uniqueValues() {
    return [];
  }

  @override
  String toString() {
    return repository.toSQLMap(this).toString();
  }

  List<String> validate() {
    return [];
  }
}

abstract class ModelRepository<T extends Model> {
  final String tableName;
  final String? writeTableName;
  final String idField;
  final String timestampField;

  final Signal<int> writeSignal = Signal(0, debugLabel: "${T}Write");

  ModelRepository(
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
    String? name, // Optional for debugging
  }) async {
    var cdb = await CarerDB.instance;
    var (where, whereArgs) = _buildWhereStatement(
        after: after, before: before, conditions: conditions);
    var res = await futureProfile(
        "$runtimeType ${name ?? "q"}",
        cdb.db.query(tableName,
            where: where,
            whereArgs: whereArgs,
            limit: limit,
            orderBy: "$timestampField DESC"));
    return res.map((e) => fromMap(e)).toList();
  }

  Future<List<T>> lastMins(int minsAgo) async {
    return (await query(
        name: "lastMins",
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch));
  }

  Future<bool> save(T model) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;

    var id = 0;
    if (model.id == null) {
      id = await cdb.db.insert(tb, toSQLMap(model),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      id = await cdb.db.update(tb, toSQLMap(model),
          where: '$idField = ?', whereArgs: [model.id]);
    }
    var ret = id != 0;
    model.id = id;
    writeSignal.value = clock.now().millisecondsSinceEpoch;
    return ret;
  }

  Future<int> saveAll(List<T> models) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;
    var batch = cdb.db.batch();

    for (var model in models) {
      if (model.id == null) {
        batch.insert(tb, toSQLMap(model),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        batch.update(tb, toSQLMap(model),
            where: '$idField = ?', whereArgs: [model.id]);
      }
    }
    var ids = await futureProfile("$T saveAll", batch.commit());
    // assign the ids
    var saves = 0;
    for (var i = 0; i < models.length; i++) {
      var id = ids[i];
      if (id != null && id != 0 && id is int) {
        models[i].id = id;
        saves++;
      }
    }

    if (saves > 0) {
      writeSignal.value = clock.now().millisecondsSinceEpoch;
    }
    return saves;
  }

  Future<bool> upsert(T model, List<String> uniqueValues) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;

    var map = toSQLMap(model);
    var keys = map.keys.toList();
    var where = uniqueValues.map((e) => '$e = ?').join(' AND ');
    var whereArgs = uniqueValues.map((e) => map[e]).toList();

    // Get current value
    var oldModel = await cdb.db
        .query(tb, columns: keys, where: where, whereArgs: whereArgs, limit: 1);

    if (oldModel.isNotEmpty) {
      // check if there is need for any changes
      var update = false;
      for (var k in keys) {
        if (oldModel.first[k] != map[k]) {
          update = true;
          break;
        }
      }

      if (update) {
        var id = await cdb.db.update(
          tb,
          map,
          where: where,
          whereArgs: whereArgs,
        );

        var ret = id != 0;
        if (ret) {
          writeSignal.value = clock.now().millisecondsSinceEpoch;
        }
        return ret;
      }
    }
    return save(model);
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
