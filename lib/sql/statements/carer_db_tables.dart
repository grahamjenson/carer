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
  sgvsCleanView,
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
      start INTEGER,
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,

      value REAL,
      UNIQUE(start, value)
    )
  ''');

const temptargetsTable = DBTable('temptargets', '''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      start INTEGER,
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,

      targetTop INTEGER,
      targetBottom INTEGER,
      UNIQUE(start, targetTop, targetBottom)
    )
  ''');

const profileTable = DBTable('profile', '''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,

      dia INTEGER,
      units TEXT,
      timezone TEXT,
      cr0 INTEGER, cr1 INTEGER, cr2 INTEGER, cr3 INTEGER, cr4 INTEGER, cr5 INTEGER, cr6 INTEGER, cr7 INTEGER, cr8 INTEGER, cr9 INTEGER, cr10 INTEGER, cr11 INTEGER, cr12 INTEGER, cr13 INTEGER, cr14 INTEGER, cr15 INTEGER, cr16 INTEGER, cr17 INTEGER, cr18 INTEGER, cr19 INTEGER, cr20 INTEGER, cr21 INTEGER, cr22 INTEGER, cr23 INTEGER,
      isf0 INTEGER, isf1 INTEGER, isf2 INTEGER, isf3 INTEGER, isf4 INTEGER, isf5 INTEGER, isf6 INTEGER, isf7 INTEGER, isf8 INTEGER, isf9 INTEGER, isf10 INTEGER, isf11 INTEGER, isf12 INTEGER, isf13 INTEGER, isf14 INTEGER, isf15 INTEGER, isf16 INTEGER, isf17 INTEGER, isf18 INTEGER, isf19 INTEGER, isf20 INTEGER, isf21 INTEGER, isf22 INTEGER, isf23 INTEGER,
      basal0 REAL, basal1 REAL, basal2 REAL, basal3 REAL, basal4 REAL, basal5 REAL, basal6 REAL, basal7 REAL, basal8 REAL, basal9 REAL, basal10 REAL, basal11 REAL, basal12 REAL, basal13 REAL, basal14 REAL, basal15 REAL, basal16 REAL, basal17 REAL, basal18 REAL, basal19 REAL, basal20 REAL, basal21 REAL, basal22 REAL, basal23 REAL,
      tlow0 INTEGER, tlow1 INTEGER, tlow2 INTEGER, tlow3 INTEGER, tlow4 INTEGER, tlow5 INTEGER, tlow6 INTEGER, tlow7 INTEGER, tlow8 INTEGER, tlow9 INTEGER, tlow10 INTEGER, tlow11 INTEGER, tlow12 INTEGER, tlow13 INTEGER, tlow14 INTEGER, tlow15 INTEGER, tlow16 INTEGER, tlow17 INTEGER, tlow18 INTEGER, tlow19 INTEGER, tlow20 INTEGER, tlow21 INTEGER, tlow22 INTEGER, tlow23 INTEGER,
      thigh0 INTEGER, thigh1 INTEGER, thigh2 INTEGER, thigh3 INTEGER, thigh4 INTEGER, thigh5 INTEGER, thigh6 INTEGER, thigh7 INTEGER, thigh8 INTEGER, thigh9 INTEGER, thigh10 INTEGER, thigh11 INTEGER, thigh12 INTEGER, thigh13 INTEGER, thigh14 INTEGER, thigh15 INTEGER, thigh16 INTEGER, thigh17 INTEGER, thigh18 INTEGER, thigh19 INTEGER, thigh20 INTEGER, thigh21 INTEGER, thigh22 INTEGER, thigh23 INTEGER,
      UNIQUE(
        dia ,
        units ,
        timezone,
        cr0 , cr1 , cr2 , cr3 , cr4 , cr5 , cr6 , cr7 , cr8 , cr9 , cr10 , cr11 , cr12 , cr13 , cr14 , cr15 , cr16 , cr17 , cr18 , cr19 , cr20 , cr21 , cr22 , cr23 ,
        isf0 , isf1 , isf2 , isf3 , isf4 , isf5 , isf6 , isf7 , isf8 , isf9 , isf10 , isf11 , isf12 , isf13 , isf14 , isf15 , isf16 , isf17 , isf18 , isf19 , isf20 , isf21 , isf22 , isf23 ,
        basal0 , basal1 , basal2 , basal3 , basal4 , basal5 , basal6 , basal7 , basal8 , basal9 , basal10 , basal11 , basal12 , basal13 , basal14 , basal15 , basal16 , basal17 , basal18 , basal19 , basal20 , basal21 , basal22 , basal23 ,
        tlow0 , tlow1 , tlow2 , tlow3 , tlow4 , tlow5 , tlow6 , tlow7 , tlow8 , tlow9 , tlow10 , tlow11 , tlow12 , tlow13 , tlow14 , tlow15 , tlow16 , tlow17 , tlow18 , tlow19 , tlow20 , tlow21 , tlow22 , tlow23 ,
        thigh0 , thigh1 , thigh2 , thigh3 , thigh4 , thigh5 , thigh6 , thigh7 , thigh8 , thigh9 , thigh10 , thigh11 , thigh12 , thigh13 , thigh14 , thigh15 , thigh16 , thigh17 , thigh18 , thigh19 , thigh20 , thigh21 , thigh22 , thigh23)
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

// SGV clean view
// CLEAN:
// Link SVGS with the previous reading that is further than 4 minutes before.
const sgvsCleanView = DBTable('sgvsClean', '''
    CREATE VIEW sgvsClean AS
    SELECT 
      safter.id as id,
      safter.value as value, 
      safter.timestamp timestamp, 
      safter.datetime datetime,
      safter.value - sbefore.value as diff,
      safter.minute_timestamp - sbefore.minute_timestamp as mins_diff,
      ((safter.value - sbefore.value) / ((safter.minute_timestamp - sbefore.minute_timestamp) / 5)) as rate5m,

      sbefore.id as id_before,
      sbefore.value as value_before,
      sbefore.timestamp ts_before, 
      sbefore.datetime dt_before
    FROM
      sgvs safter LEFT JOIN  sgvs sbefore ON sbefore.id = (
        SELECT x.id
        FROM sgvs x 
        WHERE 
          (x.minute_timestamp + 4 < safter.minute_timestamp)
        ORDER BY timestamp DESC LIMIT 1
      )
    ORDER BY
      timestamp DESC
  ''');
