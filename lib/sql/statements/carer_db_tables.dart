import 'package:carer/sql/statements/kv.dart';

class DBTable {
  final String name;
  final String create;
  const DBTable(this.name, this.create);
}

const dbTables = [
  kvTable,
  sgvTable,
  bolusTable,
  carbsTable,
  tempbasalTable,
  temptargetsTable,
  profileTable,
];

const dbViews = [
  treatmentsView,
  concatTreatmentsView,
  sgvDiffView,
];

// Used for key values like iob...
const kvTable = DBTable(KVTables.kvTableName, KVTables.kvTable);

const sgvTable = DBTable('sgvs', '''
    CREATE TABLE sgvs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      minute_timestamp INTEGER GENERATED ALWAYS AS (timestamp / 60000) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const bolusTable = DBTable('bolus', '''
    CREATE TABLE bolus (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const carbsTable = DBTable('carbs', '''
    CREATE TABLE carbs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const tempbasalTable = DBTable('tempbasal', '''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER
    )
  ''');

const temptargetsTable = DBTable('temptargets', '''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER
    )
  ''');

const profileTable = DBTable('profile', '''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      age INTEGER,
      weight REAL,
      height REAL
    )
  ''');

const treatmentsView = DBTable('treatments', '''
    CREATE VIEW treatments AS
    WITH 
    b as  (SELECT  timestamp, value as insulin FROM bolus) ,
    c as  (SELECT timestamp, value as carbs from carbs),
    x AS (SELECT b.timestamp, b.insulin, null as carbs  from b UNION SELECT c.timestamp, null as insulin, c.carbs from c)
    SELECT * from x ORDER by timestamp desc
  ''');

const concatTreatmentsView = DBTable('concatTreatments', '''
    CREATE VIEW concatTreatments AS
      SELECT
        COUNT(*) as count,
        SUM(carbs) as carbs,
        SUM(insulin) as insulin, 
        MIN(timestamp) as min_ts, 
        MAX(timestamp) as max_ts, 
        datetime(MIN(timestamp) / 1000, 'unixepoch') as min_datetime, 
        datetime(MAX(timestamp) / 1000, 'unixepoch') as max_datetime, 
        strftime('%Y-%m-%d %H ', timestamp/1000, 'unixepoch')  ||  (Floor(strftime('%M', timestamp/1000, 'unixepoch')/5) * 5) as window 
      FROM treatments 
      GROUP BY window
      ORDER BY min_ts DESC
  ''');

// SGV diff view table
const sgvDiffView = DBTable('sgvDiff', '''
    CREATE VIEW sgvDiff AS
    SELECT 
      safter.id as id,
      safter.value as value, 
      safter.timestamp timestamp, 
      safter.datetime datetime,
      safter.value - sbefore.value as diff,
      ((safter.value - sbefore.value) / ((safter.minute_timestamp - sbefore.minute_timestamp) / 5)) as rate5m,

      sbefore.id as id_before,
      sbefore.value as value_before,
      sbefore.timestamp ts_before, 
      sbefore.datetime dt_before
    FROM
      sgvs sbefore JOIN sgvs safter ON sbefore.id = (
        SELECT x.id 
        FROM sgvs x 
        WHERE 
          x.id != safter.id AND 
          x.minute_timestamp + 4 < safter.minute_timestamp 
        ORDER BY x.timestamp desc limit 1
      )
    ORDER BY
      timestamp DESC
  ''');
