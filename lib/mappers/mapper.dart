import 'package:carer/models/sql/db_model.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:sqflite/sqflite.dart';

abstract class DataMapper<T1, T2> {
  const DataMapper();

  T2 aToB(T1 model);
  T1 bToA(T2 model);

  List<T2> mapAToB(List<T1> models) {
    return models.map(aToB).toList();
  }

  List<T2> mapBToA(List<T1> models) {
    return models.map(aToB).toList();
  }

  bool equals(T1 a, T2 b) {
    throw UnimplementedError();
  }
}

abstract class SQLReadMapper<T extends DBModel> extends DataMapper<SQLRow, T> {
  String get tableName;
  String get timestampField => "timestamp";

  @override
  SQLRow bToA(T model) {
    throw UnimplementedError();
  }

  Future<List<T>> query({
    int? after,
    int? before,
    Map<String, Object?>? conditions,
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

    return mapAToB(SQLRow.fromResult(res));
  }

  Future<List<T>> lastMins(int minsAgo) {
    return query(name: "lastMins", after: clock.now().subtract(Duration(minutes: minsAgo)).millisecondsSinceEpoch);
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
  (String?, List<Object>?) _buildWhereStatement({int? after, int? before, Map<String, Object?>? conditions}) {
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
        if (value != null) {
          where.add('$key = ?');
          whereArgs.add(value);
        } else {
          where.add('$key IS NULL');
        }
      });
    }
    if (where.isEmpty) {
      return (null, null);
    }
    return (where.join(' AND '), whereArgs);
  }
}

abstract class SQLMapper<T extends DBModel> extends SQLReadMapper<T> {
  final ASignal<int> writeSignal = ASignal(0, debugLabel: "${T}Write");

  Future<bool> saveRow(SQLRow row) {
    return save(aToB(row));
  }

  Future<bool> save(T model, {bool withSignal = true}) async {
    var cdb = await CarerDB.instance;
    var tb = tableName;

    int? id;
    Object? err;
    if (model.id == null) {
      (id, err) = await go(cdb.db.insert(tb, bToA(model).toMap(), conflictAlgorithm: ConflictAlgorithm.ignore));
    } else {
      (id, err) = await go(cdb.db.update(tb, bToA(model).toMap(), where: 'id = ?', whereArgs: [model.id]));
    }
    if (err != null) {
      return false;
    }

    var ret = id != 0;
    if (ret) {
      model.id = id;
      if (withSignal) {
        writeSignal.value = clock.now().millisecondsSinceEpoch;
      }
    }
    return ret;
  }

  Future<int> saveAll(List<T> models, {bool withSignal = true}) async {
    var cdb = await CarerDB.instance;
    var tb = tableName;
    var batch = cdb.db.batch();

    for (var model in models) {
      if (model.id == null) {
        batch.insert(tb, bToA(model).toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        batch.update(tb, bToA(model).toMap(), where: 'id = ?', whereArgs: [model.id]);
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
      if (withSignal) {
        writeSignal.value = clock.now().millisecondsSinceEpoch;
      }
    }
    return saves;
  }

  Future<int> upsertAll(List<T> models) async {
    var cdb = await CarerDB.instance;
    var tb = tableName;

    // Fetch all models with id or eid
    Map<int, T> idMap = {};
    Map<String, T> eidMap = {};

    for (var m in models) {
      if (m.id != null) {
        idMap[m.id!] = m;
      } else if (m.eid != null) {
        eidMap[m.eid!] = m;
      }
    }

    List<dynamic> ids = idMap.keys.toList();
    List<dynamic> eids = eidMap.keys.toList();
    List<dynamic> combinedList = [];
    combinedList.addAll(ids);
    combinedList.addAll(eids);

    var (dbModels, err) = await go(cdb.db.query(
      tb,
      where: "id IN (${List.filled(ids.length, '?').join(',')}) OR eid IN (${List.filled(eids.length, '?').join(',')})",
      whereArgs: combinedList,
    ));
    if (err != null || dbModels == null) {
      return 0;
    }

    // Match the models with their counter part in the db, also update model id
    Map<T, Map<String, Object?>> dbModelMap = {};

    for (var dbModel in dbModels) {
      var id = dbModel["id"];
      if (id != null && idMap.containsKey(id)) {
        dbModelMap[idMap[id]!] = dbModel;
        continue;
      }

      var eid = dbModel["eid"];
      if (eid != null && eidMap.containsKey(eid)) {
        dbModelMap[eidMap[eid]!] = dbModel;
      }
    }

    List<T> saveOrUpdateModels = [];

    // This checks to see if the model is different
    for (var model in models) {
      var dbModel = dbModelMap[model];
      if (dbModel == null) {
        // Add value to list that doesnt exist in the db
        saveOrUpdateModels.add(model);
        continue;
      }

      if (!equals(SQLRow(dbModel), model)) {
        saveOrUpdateModels.add(model);
        // Force update of model to make sure saveAll updates
        model.id = dbModel["id"]! as int;
      }
    }

    if (saveOrUpdateModels.isEmpty) {
      return 0;
    }

    return saveAll(saveOrUpdateModels);
  }

  Future<bool> _upsert(T model, {bool withSignal = true}) async {
    var cdb = await CarerDB.instance;
    var tb = tableName;

    // We look for the model using the id, or eid

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
    var (oldModels, err) = await go(cdb.db.query(tb, where: where, whereArgs: whereArgs, limit: 1));
    if (err != null || oldModels == null) {
      return false;
    }

    // The model doesn exist, insert
    if (oldModels.isEmpty) {
      return save(model, withSignal: withSignal);
    }

    var oldModel = oldModels.first;

    // If current model and old model equal do nothing
    if (equals(SQLRow(oldModel), model)) {
      return false;
    }

    var (id, err2) = await go(cdb.db.update(
      tb,
      bToA(model).toMap(),
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
}
