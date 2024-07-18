import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sqflite/sqflite.dart';

abstract class Model<T> {
  int? id;
  String? eid;

  Model({this.id, this.eid});
  DateTime get date;
  ModelRepository get repository;

  Duration get age {
    return clock.now().difference(date);
  }

  Future<bool> save() {
    return go(repository.save(this), name: "$runtimeType save", profile: true).then((value) {
      var (res, err) = value;
      if (err != null || res == null) {
        return false;
      }
      return res;
    });
  }

  Future<bool> upsert() {
    return go(repository.upsert(this), name: "$runtimeType upsert", profile: true).then((value) {
      var (res, err) = value;
      if (err != null || res == null) {
        return false;
      }
      return res;
    });
  }

  @override
  String toString() {
    return repository.toSQLMap(this).toString();
  }

  // wrapper around SQLMap
  Map<String, Object> toSQLMap() {
    return repository.toSQLMap(this);
  }

  //check if this model is equal to another sql map
  bool equalsSQLMap(Map<String, Object?> map) {
    return toSQLMap().entries.every((e) {
      return map[e.key] == e.value;
    });
  }

  List<String> validate() {
    return [];
  }

  static cleanSignals() {
    Bolus.writeSignal.value = 0;
    Carbs.writeSignal.value = 0;
    Profile.writeSignal.value = 0;
    SGV.writeSignal.value = 0;
    TempBasal.writeSignal.value = 0;
    TempTarget.writeSignal.value = 0;
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
    String? orderBy,
  }) async {
    var cdb = await CarerDB.instance;
    orderBy ??= "$timestampField DESC";
    var (where, whereArgs) = _buildWhereStatement(after: after, before: before, conditions: conditions);
    var (res, err) = await go(
      cdb.db.query(tableName, where: where, whereArgs: whereArgs, limit: limit, orderBy: orderBy),
      name: "$runtimeType ${name ?? "q"}",
      profile: true,
    );
    if (err != null || res == null) {
      return [];
    }
    return res.map((e) => fromMap(e)).toList();
  }

  Future<List<T>> lastMins(int minsAgo) {
    return query(name: "lastMins", after: clock.now().subtract(Duration(minutes: minsAgo)).millisecondsSinceEpoch);
  }

  Future<bool> save(T model, {bool withSignal = true}) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;

    var id;
    var err;
    if (model.id == null) {
      (id, err) = await go(cdb.db.insert(tb, toSQLMap(model), conflictAlgorithm: ConflictAlgorithm.ignore));
    } else {
      (id, err) = await go(cdb.db.update(tb, toSQLMap(model), where: '$idField = ?', whereArgs: [model.id]));
    }
    if (err != null) {
      return false;
    }

    var ret = id != null && id != 0;
    if (ret) {
      model.id = id;
      if (withSignal) {
        writeSignal.value = clock.now().millisecondsSinceEpoch;
      }
    }
    return ret;
  }

  Future<int> saveAll(List<T> models) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;
    var batch = cdb.db.batch();

    for (var model in models) {
      if (model.id == null) {
        batch.insert(tb, toSQLMap(model), conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        batch.update(tb, toSQLMap(model), where: '$idField = ?', whereArgs: [model.id]);
      }
    }
    var (ids, err) = await go(
      batch.commit(),
      name: "$T saveAll",
      profile: true,
    );
    if (err != null || ids == null) {
      return 0;
    }
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

  Future<int> upsertAll(List<T> models) async {
    List<bool> modelsss = [];
    for (var m in models) {
      modelsss.add(await upsert(m, withSignal: false));
    }
    var total = modelsss.where((e) => e).length;
    if (total > 0) {
      writeSignal.value = clock.now().millisecondsSinceEpoch;
    }
    return total;
  }

  Future<bool> upsert(T model, {bool withSignal = true}) async {
    var cdb = await CarerDB.instance;
    var tb = writeTableName ?? tableName;

    // We look for the model using the id, or eid
    var modelSQL = toSQLMap(model);
    var keys = modelSQL.keys.toList();
    var where = "";

    List whereArgs = [];
    if (model.id != null) {
      where = 'id = ?';
      whereArgs = [model.id!];
    } else if (model.eid != null) {
      where = 'eid = ?';
      whereArgs = [model.eid!];
    } else {
      return save(model, withSignal: withSignal);
    }

    // Get current value
    var (oldModels, err) = await go(cdb.db.query(tb, columns: keys, where: where, whereArgs: whereArgs, limit: 1));
    if (err != null || oldModels == null) {
      return false;
    }

    // The model doesn exist, insert
    if (oldModels.isEmpty) {
      return save(model, withSignal: withSignal);
    }

    var oldModel = oldModels.first;
    // If current model and old model equal do nothing
    if (model.equalsSQLMap(oldModel)) {
      return false;
    }

    var (id, err2) = await go(cdb.db.update(
      tb,
      modelSQL,
      where: where,
      whereArgs: whereArgs,
    ));
    if (err2 != null) {
      return false;
    }
    var ret = id != null && id != 0;
    if (ret) {
      if (withSignal) {
        writeSignal.value = clock.now().millisecondsSinceEpoch;
      }
    }

    return ret;
  }

  Future<int?> count({int? after, int? before, Map<String, Object>? conditions}) async {
    var cdb = await CarerDB.instance;
    var (where, whereArgs) = _buildWhereStatement(after: after, before: before, conditions: conditions);

    var (res, err) = await go(cdb.db.query(tableName, columns: ['COUNT(*)'], where: where, whereArgs: whereArgs));
    if (err != null || res == null) {
      return null;
    }
    return res.first.values.first as int?;
  }

  // utils
  (String?, List<Object>?) _buildWhereStatement({int? after, int? before, Map<String, Object>? conditions}) {
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

  bool validateType(Map<String, Object?> m, List<(String, Type)> keysTypes) {
    for (var i = 0; i < keysTypes.length; i++) {
      var (key, type) = keysTypes[i];
      if (m[key] == null) {
        continue; // Ignore if null
      }
      if (m[key].runtimeType != type) {
        alog("BAD KEY TYPE $key ${m[key]} $type");
        return false;
      }
    }
    return true;
  }
}

abstract class DateRangeModel extends Model {
  @override
  get date => startDate;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;

  DateRangeModel({
    super.id,
    super.eid,
    required this.startDate,
    required this.endDate,
    required this.duration,
  });

  Duration get remaining {
    return endDate.difference(clock.now());
  }

  bool isAtTime(DateTime date) {
    return date.isAfter(startDate) && date.isBefore(endDate);
  }
}
