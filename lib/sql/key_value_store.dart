// This key-value store is a wrapper around sqllite for key value storage.
// It will make it easier to have a single location for all persisted entities.
// Hopefully, this will make it easier to manage the data.

import 'package:carer/sql/db.dart';
import 'package:carer/sql/statements/kv.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:sqflite/sqflite.dart';

class KeyValueStore {
  final Database _db;
  final Map<String, dynamic> _cache = {};
  Map<String, dynamic> get cache => _cache;

  static final Future<KeyValueStore> _instance = _createInstance();
  static Future<KeyValueStore> get instance => _instance;

  KeyValueStore(this._db);

  static Future<String> getPath() async {
    return DB.getPath("kv");
  }

  // Constructor
  static Future<KeyValueStore> _createInstance() async {
    final db = await openDatabaseAndCreateTables();
    var kvdb = KeyValueStore(db);
    await kvdb.internalPopulate();
    return kvdb;
  }

  // Open the database and create the tables
  static Future<Database> openDatabaseAndCreateTables() async {
    final path = await getPath();

    alog("Opening keyvalue DB at $path");

    var db = await openDatabase(
      path,
      version: 1,
      singleInstance: DB.singleInstance,
      onCreate: (db, version) async {
        var batch = db.batch();
        batch.execute(KVTables.kvTable);
        await batch.commit();
      },
    );

    await DB.setPragma("kv", db);

    return db;
  }

  // populate the cache
  Future<bool> internalPopulate() async {
    var (results, err) = await go(_db.query(KVTables.kvTableName));
    if (err != null || results == null) {
      return false;
    }
    for (var result in results) {
      if (result['k'] == null || result['v'] == null || result['t'] == null) {
        continue;
      }

      String key = "${result['k']}";
      String value = "${result['v']}";
      String type = "${result['t']}";

      switch (type) {
        case 'Bool':
          _cache[key] = value == '1';
          break;
        case 'Int':
          _cache[key] = int.parse(value);
          break;
        case 'Double':
          _cache[key] = double.parse(value);
          break;
        case 'String':
          _cache[key] = value;
          break;
        default:
          _cache[key] = value;
          break;
      }
    }
    return true;
  }

  int count() {
    return _cache.length;
  }

  reloadCache() async {
    _cache.clear();
    await internalPopulate();
  }

  Future<int> deleteAll() async {
    _cache.clear();
    var (ret, err) = await go(_db.delete(KVTables.kvTableName));
    if (err != null || ret == null) {
      return 0;
    }
    return ret;
  }

  Future<bool> delete(String key) async {
    _cache.remove(key);
    var (ret, err) = await go(_db.rawDelete(KVQueries.delete, [key]));
    if (err != null || ret == null) {
      return false;
    }
    return ret == 1;
  }

  // Getter Setters
  Set<String> getKeys() => Set<String>.from(_cache.keys);

  /// Reads a value of any type from persistent storage.
  Object? get(String key, {Object? defaultValue}) => _cache[key] ?? defaultValue;

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// bool.
  bool? getBool(String key, {bool? defaultValue}) => _cache[key] ?? defaultValue;

  /// Reads a value from persistent storage, throwing an exception if it's not
  /// an int.
  int? getInt(String key, {int? defaultValue}) => _cache[key] ?? defaultValue;

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// double.
  double? getDouble(String key, {double? defaultValue}) {
    var val = _cache[key] ?? defaultValue;
    if (val is int) {
      return val.toDouble();
    }
    return val;
  }

  /// Reads a value from persistent storage, throwing an exception if it's not a
  /// String.
  String? getString(String key, {String? defaultValue}) => _cache[key] ?? defaultValue;

  /// Returns true if the persistent storage contains the given [key].
  bool containsKey(String key) => _cache.containsKey(key);

  /// Saves a boolean [value] to persistent storage in the background.
  Future<bool> setBool(String key, bool value) => _setValue('Bool', key, value);

  /// Saves an integer [value] to persistent storage in the background.
  Future<bool> setInt(String key, int value) => _setValue('Int', key, value);

  /// Saves a double [value] to persistent storage in the background.
  ///
  /// Android doesn't support storing doubles, so it will be stored as a float.
  Future<bool> setDouble(String key, double value) => _setValue('Double', key, value);

  /// Saves a string [value] to persistent storage in the background.
  Future<bool> setString(String key, String value) => _setValue('String', key, value);

  Future<bool> _setValue(String valueType, String key, Object value) async {
    ArgumentError.checkNotNull(value, 'value');
    var oldValue = _cache[key];
    if (oldValue == value) {
      return false;
    }
    _cache[key] = value;

    if (valueType == 'Bool') {
      value = (value as bool) ? '1' : '0';
    }

    var (ret, err) = await go(_db.rawInsert(KVQueries.upsert, [key, value, valueType, value, valueType]));
    if (err != null || ret == null) {
      return false;
    }
    return ret == 1;
  }
}
