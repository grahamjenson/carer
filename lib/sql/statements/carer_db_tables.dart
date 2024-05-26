class DBTables {
  static const sgvTableName = 'sgvs';
  static const bolusTableName = 'bolus';
  static const carbsTableName = 'carbs';
  static const tempbasalTableName = 'tempbasal';
  static const temptargetsTableName = 'temptargets';
  static const profileTableName = 'profile';
  static const treatmentsViewName = "treatments";

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

  static const String bolusTable = '''
    CREATE TABLE $bolusTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''';

  static const String bolusIndex = '''
    CREATE INDEX bolus_date_index ON $bolusTableName (timestamp)
  ''';

  static const String carbsTable = '''
    CREATE TABLE $carbsTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''';

  static const String carbsndex = '''
    CREATE INDEX carbs_date_index ON $carbsTableName (timestamp)
  ''';

  static const String tempbasalTable = '''
    CREATE TABLE $tempbasalTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER
    )
  ''';

  static const String temptargetsTable = '''
    CREATE TABLE $temptargetsTableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER
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

  ////
  // Views
  ////

  static const String treatmentsView = '''
    CREATE VIEW $treatmentsViewName AS
    WITH 
    b as  (SELECT  timestamp, value as insulin FROM $bolusTableName) ,
    c as  (SELECT timestamp, value as carbs from $carbsTableName),
    x AS (SELECT b.timestamp, b.insulin, null as carbs  from b UNION SELECT c.timestamp, null as insulin, c.carbs from c)
	  SELECT * from x ORDER by timestamp desc
  ''';
}
