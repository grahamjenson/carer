class DBTables {
  static const String sgvTable = '''
    CREATE TABLE sgvs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      date INTEGER,
      UNIQUE(value, date)
    )
  ''';

  static const String insulinTable = '''
    CREATE TABLE insulin (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String carbsTable = '''
    CREATE TABLE carbs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String tempbasalTable = '''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      date INTEGER
    )
  ''';

  static const String temptargetsTable = '''
    CREATE TABLE temptargets (
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
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      age INTEGER,
      weight REAL,
      height REAL
    )
  ''';
}
