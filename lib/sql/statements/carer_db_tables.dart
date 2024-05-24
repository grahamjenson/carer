class DBTables {
  static const sgvTableName = 'sgvs';
  static const insulinTableName = 'insulin';
  static const carbsTableName = 'carbs';
  static const tempbasalTableName = 'tempbasal';
  static const temptargetsTableName = 'temptargets';
  static const profileTableName = 'profile';

  static const String sgvTable = '''
    CREATE TABLE $sgvTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''';

  static const String sgvIndex = '''
    CREATE INDEX sgv_date_index ON $sgvTableName (timestamp)
  ''';

  static const String insulinTable = '''
    CREATE TABLE $insulinTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String carbsTable = '''
    CREATE TABLE $carbsTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String tempbasalTable = '''
    CREATE TABLE $tempbasalTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String temptargetsTable = '''
    CREATE TABLE $temptargetsTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

////
// PROFILE
////

// Should we denormalize and have [24] array for each type of basal, carb ratio, etc?
// Yes, then we can do comparisons easier
  static const String profileTable = '''
    CREATE TABLE $profileTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      age INTEGER,
      weight REAL,
      height REAL
    )
  ''';
}
