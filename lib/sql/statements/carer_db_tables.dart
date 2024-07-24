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
  valuesAtTimeTable,
  logsTable,
];

const dbViews = [
  treatmentsView,
  concatTreatmentsView,
  sgvsCleanView,
];

// Used for key values like iob...
const kvTable = DBTable(KVTables.kvTableName, KVTables.kvTable);

const String sgvsTableName = 'sgvs';
const sgvTable = DBTable(sgvsTableName, '''

    CREATE TABLE sgvs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      minute_timestamp INTEGER GENERATED ALWAYS AS (timestamp / 60000) VIRTUAL,
      UNIQUE(eid)
    )
  ''');

const String bolusTableName = 'bolus';
const bolusTable = DBTable(bolusTableName, '''
    CREATE TABLE bolus (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      value REAL,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(eid)
    )
  ''');

const String carbsTableName = 'carbs';
const carbsTable = DBTable(carbsTableName, '''
    CREATE TABLE carbs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(eid)
    )
  ''');

const String tempbasalTableName = 'tempbasal';
const tempbasalTable = DBTable(tempbasalTableName, '''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      start INTEGER,
      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,
      value REAL,
      UNIQUE(eid)
    )
  ''');

const String temptargetsTableName = 'temptargets';
const temptargetsTable = DBTable(temptargetsTableName, '''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      start INTEGER,
      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,

      highTarget INTEGER,
      lowTarget INTEGER,
      UNIQUE(eid)
    )
  ''');

// Profile includes the profile,
// If duration is 0 then it is indefinite
// This is constructed from various sources, the idea is to have a table which is queryable for the current profile given a time
const String profileTableName = 'profile';
const profileTable = DBTable(profileTableName, '''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      name TEXT,
      
      -- Date stuff
      start INTEGER,
      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      duration INTEGER,

      -- If duration is 0, it means that it is actually indefinite
      -- we use ~100 years (in seconds) as an aproximate value
      actual_duration INTEGER GENERATED ALWAYS AS (
        CASE 
          WHEN duration = 0 THEN 3000000000
          ELSE duration
        END
      ) VIRTUAL,

      end INTEGER GENERATED ALWAYS AS (start + (actual_duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,
       
      
      source TEXT,
      percent INTEGER,

      dia INTEGER,
      units TEXT,
      timezone TEXT,
      cr0 INTEGER, cr1 INTEGER, cr2 INTEGER, cr3 INTEGER, cr4 INTEGER, cr5 INTEGER, cr6 INTEGER, cr7 INTEGER, cr8 INTEGER, cr9 INTEGER, cr10 INTEGER, cr11 INTEGER, cr12 INTEGER, cr13 INTEGER, cr14 INTEGER, cr15 INTEGER, cr16 INTEGER, cr17 INTEGER, cr18 INTEGER, cr19 INTEGER, cr20 INTEGER, cr21 INTEGER, cr22 INTEGER, cr23 INTEGER,
      isf0 INTEGER, isf1 INTEGER, isf2 INTEGER, isf3 INTEGER, isf4 INTEGER, isf5 INTEGER, isf6 INTEGER, isf7 INTEGER, isf8 INTEGER, isf9 INTEGER, isf10 INTEGER, isf11 INTEGER, isf12 INTEGER, isf13 INTEGER, isf14 INTEGER, isf15 INTEGER, isf16 INTEGER, isf17 INTEGER, isf18 INTEGER, isf19 INTEGER, isf20 INTEGER, isf21 INTEGER, isf22 INTEGER, isf23 INTEGER,
      basal0 REAL, basal1 REAL, basal2 REAL, basal3 REAL, basal4 REAL, basal5 REAL, basal6 REAL, basal7 REAL, basal8 REAL, basal9 REAL, basal10 REAL, basal11 REAL, basal12 REAL, basal13 REAL, basal14 REAL, basal15 REAL, basal16 REAL, basal17 REAL, basal18 REAL, basal19 REAL, basal20 REAL, basal21 REAL, basal22 REAL, basal23 REAL,
      tlow0 INTEGER, tlow1 INTEGER, tlow2 INTEGER, tlow3 INTEGER, tlow4 INTEGER, tlow5 INTEGER, tlow6 INTEGER, tlow7 INTEGER, tlow8 INTEGER, tlow9 INTEGER, tlow10 INTEGER, tlow11 INTEGER, tlow12 INTEGER, tlow13 INTEGER, tlow14 INTEGER, tlow15 INTEGER, tlow16 INTEGER, tlow17 INTEGER, tlow18 INTEGER, tlow19 INTEGER, tlow20 INTEGER, tlow21 INTEGER, tlow22 INTEGER, tlow23 INTEGER,
      thigh0 INTEGER, thigh1 INTEGER, thigh2 INTEGER, thigh3 INTEGER, thigh4 INTEGER, thigh5 INTEGER, thigh6 INTEGER, thigh7 INTEGER, thigh8 INTEGER, thigh9 INTEGER, thigh10 INTEGER, thigh11 INTEGER, thigh12 INTEGER, thigh13 INTEGER, thigh14 INTEGER, thigh15 INTEGER, thigh16 INTEGER, thigh17 INTEGER, thigh18 INTEGER, thigh19 INTEGER, thigh20 INTEGER, thigh21 INTEGER, thigh22 INTEGER, thigh23 INTEGER,
      UNIQUE(eid)
    )
  ''');

const String treatmentsViewName = 'treatments';
const treatmentsView = DBTable(treatmentsViewName, '''
    CREATE VIEW treatments AS
    WITH 
    b AS  (SELECT  timestamp, value AS insulin FROM bolus) ,
    c AS  (SELECT timestamp, value AS carbs FROM carbs),
    x AS (SELECT b.timestamp, b.insulin, null AS carbs  FROM b UNION SELECT c.timestamp, null AS insulin, c.carbs FROM c)
    SELECT * FROM x ORDER by timestamp desc
  ''');

const String concatTreatmentsViewName = 'concatTreatments';
const concatTreatmentsView = DBTable(concatTreatmentsViewName, '''
    CREATE VIEW concatTreatments AS
      SELECT
        COUNT(*) AS count,
        SUM(carbs) AS carbs,
        SUM(insulin) AS insulin, 
        MIN(timestamp) AS min_ts, 
        MAX(timestamp) AS max_ts,
        MAX(timestamp) AS timestamp,
        datetime(MIN(timestamp) / 1000, 'unixepoch') AS min_datetime, 
        datetime(MAX(timestamp) / 1000, 'unixepoch') AS max_datetime, 
        strftime('%Y-%m-%d %H ', timestamp/1000, 'unixepoch')  ||  (Floor(strftime('%M', timestamp/1000, 'unixepoch')/5) * 5) AS window 
      FROM treatments 
      GROUP BY window
      ORDER BY min_ts DESC
  ''');

// SGV clean view
// CLEAN:
// Link SVGS WITH the previous reading that is further than 4 minutes before.
const String sgvsCleanViewName = 'sgvsClean';
const sgvsCleanView = DBTable(sgvsCleanViewName, '''
    CREATE VIEW sgvsClean AS
    SELECT 
      safter.id AS id,
      safter.eid AS eid,
      safter.value AS value, 
      safter.timestamp timestamp, 
      safter.datetime datetime,
      safter.value - sbefore.value AS diff,
      
      safter.minute_timestamp - sbefore.minute_timestamp AS mins_diff,
      ((safter.value - sbefore.value) / ((safter.minute_timestamp - sbefore.minute_timestamp) / 5)) AS rate5m,

      sbefore.id AS id_before,
      sbefore.value AS value_before,
      sbefore.timestamp ts_before, 
      sbefore.datetime dt_before
    FROM
      -- This joins the current reading with the previous reading that is more than 4 minutes before.
      -- So that we can calculate rate of change.
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

// This table is a cache of minute-by-minute values
// The goal is to be used for visualization, and basically the API I wish NS had
const String valuesAtTimeTableName = "valuesAtTime";
const valuesAtTimeTable = DBTable(valuesAtTimeTableName, '''
    CREATE TABLE valuesAtTime (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid STRING,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      minute_timestamp INTEGER GENERATED ALWAYS AS (timestamp / 60000) VIRTUAL, -- minutes since epoch

      lowTarget INTEGER,
      highTarget INTEGER,
      basal REAL,
      isf INTEGER,
      cr INTEGER,

      isTempProfile INTEGER, -- 0 or 1 BOOL
      isTempTarget INTEGER,   -- 0 or 1 BOOL
      isTempBasal INTEGER,    -- 0 or 1 BOOL

      profileName TEXT,
      profilePercent INTEGER,

      UNIQUE(eid)
    )
  ''');

const String logsTableName = 'logs';
const logsTable = DBTable(logsTableName, '''
    CREATE TABLE logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      level TEXT,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      message TEXT
    )
  ''');
