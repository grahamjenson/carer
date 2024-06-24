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
  timestampMinutesView,
  profileHourView,
  valuesAtTimeView,
];

// Used for key values like iob...
const kvTable = DBTable(KVTables.kvTableName, KVTables.kvTable);

const String sgvsTableName = 'sgvs';
const sgvTable = DBTable(sgvsTableName, '''
    CREATE TABLE sgvs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      minute_timestamp INTEGER GENERATED ALWAYS AS (timestamp / 60000) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const String bolusTableName = 'bolus';
const bolusTable = DBTable(bolusTableName, '''
    CREATE TABLE bolus (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value REAL,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const String carbsTableName = 'carbs';
const carbsTable = DBTable(carbsTableName, '''
    CREATE TABLE carbs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      value INTEGER,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      UNIQUE(value, timestamp)
    )
  ''');

const String tempbasalTableName = 'tempbasal';
const tempbasalTable = DBTable(tempbasalTableName, '''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      start INTEGER,
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,

      value REAL,
      UNIQUE(start)
    )
  ''');

const String temptargetsTableName = 'temptargets';
const temptargetsTable = DBTable(temptargetsTableName, '''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      start INTEGER,
      duration INTEGER,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,

      targetHigh INTEGER,
      targetLow INTEGER,
      UNIQUE(start)
    )
  ''');

// TODO this doesnt work because you could have profile1 -> profile2 -> profile1 which would mean profile 1 has multiple start stop dates
// TODO need to find real start and stop dates for profiles to properly find real start/stop dates ON them.
const String profileTableName = 'profile';
const profileTable = DBTable(profileTableName, '''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER,
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,

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

const String treatmentsTableName = 'treatments';
const treatmentsView = DBTable(treatmentsTableName, '''
    CREATE VIEW treatments AS
    WITH 
    b AS  (SELECT  timestamp, value AS insulin FROM bolus) ,
    c AS  (SELECT timestamp, value AS carbs FROM carbs),
    x AS (SELECT b.timestamp, b.insulin, null AS carbs  FROM b UNION SELECT c.timestamp, null AS insulin, c.carbs FROM c)
    SELECT * FROM x ORDER by timestamp desc
  ''');

const String concatTreatmentsTableName = 'concatTreatments';
const concatTreatmentsView = DBTable(concatTreatmentsTableName, '''
    CREATE VIEW concatTreatments AS
      SELECT
        COUNT(*) AS count,
        SUM(carbs) AS carbs,
        SUM(insulin) AS insulin, 
        MIN(timestamp) AS min_ts, 
        MAX(timestamp) AS max_ts, 
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
const String sgvsCleanViewTableName = 'sgvsClean';
const sgvsCleanView = DBTable(sgvsCleanViewTableName, '''
    CREATE VIEW sgvsClean AS
    SELECT 
      safter.id AS id,
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

// Profile hour table, each profile is exploded into the values they provide each hour

const String profileHourViewName = "profileHourView";
const profileHourView = DBTable(profileHourViewName, '''
 CREATE VIEW profileHourView AS
WITH hours(hour) AS (
  values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23)
)
SELECT id, hour, timestamp, datetime, dia, units, timezone,
CASE hour 
	WHEN 0 THEN cr0
  WHEN 1 THEN cr1
  WHEN 2 THEN cr2
  WHEN 3 THEN cr3
	WHEN 4 THEN cr4
  WHEN 5 THEN cr5
  WHEN 6 THEN cr6
  WHEN 7 THEN cr7
	WHEN 8 THEN cr8
  WHEN 9 THEN cr9
  WHEN 10 THEN cr10
  WHEN 11 THEN cr11
	WHEN 12 THEN cr12
  WHEN 13 THEN cr13
  WHEN 14 THEN cr14
  WHEN 15 THEN cr15
	WHEN 16 THEN cr16
  WHEN 17 THEN cr17
  WHEN 18 THEN cr18
  WHEN 19 THEN cr19
	WHEN 20 THEN cr20
  WHEN 21 THEN cr21
  WHEN 22 THEN cr22
  WHEN 23 THEN cr23
END cr,
CASE hour 
	WHEN 0 THEN isf0
  WHEN 1 THEN isf1
  WHEN 2 THEN isf2
  WHEN 3 THEN isf3
	WHEN 4 THEN isf4
  WHEN 5 THEN isf5
  WHEN 6 THEN isf6
  WHEN 7 THEN isf7
	WHEN 8 THEN isf8
  WHEN 9 THEN isf9
  WHEN 10 THEN isf10
  WHEN 11 THEN isf11
	WHEN 12 THEN isf12
  WHEN 13 THEN isf13
  WHEN 14 THEN isf14
  WHEN 15 THEN isf15
	WHEN 16 THEN isf16
  WHEN 17 THEN isf17
  WHEN 18 THEN isf18
  WHEN 19 THEN isf19
	WHEN 20 THEN isf20
  WHEN 21 THEN isf21
  WHEN 22 THEN isf22
  WHEN 23 THEN isf23
END isf,
CASE hour 
	WHEN 0 THEN basal0
  WHEN 1 THEN basal1
  WHEN 2 THEN basal2
  WHEN 3 THEN basal3
	WHEN 4 THEN basal4
  WHEN 5 THEN basal5
  WHEN 6 THEN basal6
  WHEN 7 THEN basal7
	WHEN 8 THEN basal8
  WHEN 9 THEN basal9
  WHEN 10 THEN basal10
  WHEN 11 THEN basal11
	WHEN 12 THEN basal12
  WHEN 13 THEN basal13
  WHEN 14 THEN basal14
  WHEN 15 THEN basal15
	WHEN 16 THEN basal16
  WHEN 17 THEN basal17
  WHEN 18 THEN basal18
  WHEN 19 THEN basal19
	WHEN 20 THEN basal20
  WHEN 21 THEN basal21
  WHEN 22 THEN basal22
  WHEN 23 THEN basal23
END basal,
CASE hour 
	WHEN 0 THEN tlow0
  WHEN 1 THEN tlow1
  WHEN 2 THEN tlow2
  WHEN 3 THEN tlow3
	WHEN 4 THEN tlow4
  WHEN 5 THEN tlow5
  WHEN 6 THEN tlow6
  WHEN 7 THEN tlow7
	WHEN 8 THEN tlow8
  WHEN 9 THEN tlow9
  WHEN 10 THEN tlow10
  WHEN 11 THEN tlow11
	WHEN 12 THEN tlow12
  WHEN 13 THEN tlow13
  WHEN 14 THEN tlow14
  WHEN 15 THEN tlow15
	WHEN 16 THEN tlow16
  WHEN 17 THEN tlow17
  WHEN 18 THEN tlow18
  WHEN 19 THEN tlow19
	WHEN 20 THEN tlow20
  WHEN 21 THEN tlow21
  WHEN 22 THEN tlow22
  WHEN 23 THEN tlow23
END tlow,
CASE hour 
	WHEN 0 THEN thigh0
  WHEN 1 THEN thigh1
  WHEN 2 THEN thigh2
  WHEN 3 THEN thigh3
	WHEN 4 THEN thigh4
  WHEN 5 THEN thigh5
  WHEN 6 THEN thigh6
  WHEN 7 THEN thigh7
	WHEN 8 THEN thigh8
  WHEN 9 THEN thigh9
  WHEN 10 THEN thigh10
  WHEN 11 THEN thigh11
	WHEN 12 THEN thigh12
  WHEN 13 THEN thigh13
  WHEN 14 THEN thigh14
  WHEN 15 THEN thigh15
	WHEN 16 THEN thigh16
  WHEN 17 THEN thigh17
  WHEN 18 THEN thigh18
  WHEN 19 THEN thigh19
	WHEN 20 THEN thigh20
  WHEN 21 THEN thigh21
  WHEN 22 THEN thigh22
  WHEN 23 THEN thigh23
END thigh
FROM 
	hours JOIN profile;
''');

// This is a list of timestamps for a large amount of time.
const String timestampMinutesViewName = "timestampMinutes";
const timestampMinutesView = DBTable(timestampMinutesViewName, '''
CREATE VIEW timestampMinutes AS
WITH minutes(minute) AS (
  values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),(41),(42),(43),(44),(45),(46),(47),(48),(49),(50),(51),(52),(53),(54),(55),(56),(57),(58),(59)
),
hours(hour) AS (values (0), (1), (2), (3), (4), (5)),
times AS (
  SELECT (strftime('%s',datetime(strftime('%Y-%m-%d %H:%M:00', 'now') )) - (60 * minute) - (hour * 60*60)) * 1000 AS timestamp
  FROM minutes join hours
)
SELECT 
  timestamp,
  datetime(timestamp / 1000, 'unixepoch') AS datetime,
  CAST(strftime('%H',datetime(timestamp / 1000, 'unixepoch'),'localtime') as INT) as hour
FROM times
ORDER BY timestamp desc;
''');

// this takes all temptarget start and endtiems AS that is when things change.
const String valuesAtTimeViewName = "valuesAtTime";
const valuesAtTimeView = DBTable(valuesAtTimeViewName, '''
CREATE VIEW valuesAtTime AS
WITH
  -- TODO get the latest profile should later get profile per time
  current_profile AS (SELECT id FROM profile ORDER BY timestamp desc limit 1),
  profile_hours AS (SELECT * FROM current_profile JOIN profileHourView ON current_profile.id = profileHourView.id),
  profile_targets AS (
    SELECT 
      timestampMinutes.timestamp,
      timestampMinutes.datetime, 
      timestampMinutes.hour, 
      profile_hours.tlow AS profile_low, 
      profile_hours.thigh AS profile_high,
      profile_hours.basal AS profile_basal,
      profile_hours.isf AS profile_isf,
      profile_hours.cr AS profile_cr
    FROM 
      timestampMinutes JOIN profile_hours ON timestampMinutes.hour = profile_hours.hour
  ),
ltempbasal as (select * from tempbasal where datetime(end/1000, 'unixepoch')  > datetime('now', '-2 hours')),
ltemptargets as (select * from temptargets where datetime(end/1000, 'unixepoch')  > datetime('now', '-2 hours'))
SELECT 
  timestamp, 
  datetime, 
  COALESCE(ltemptargets.targetLow, profile_low) AS targetLow, 
  COALESCE(ltemptargets.targetHigh, profile_high) AS targetHigh, 
  COALESCE(ltempbasal.value, profile_basal) AS basal,
  profile_isf as isf,
  profile_cr as cr,
  ltemptargets.targetHigh is not NULL AS isTempTarget,
  ltempbasal.value is not NULL AS isTempBasal 
FROM 
  profile_targets 
  LEFT JOIN ltemptargets ON profile_targets.timestamp >= ltemptargets.start and profile_targets.timestamp < ltemptargets.end
  LEFT JOIN ltempbasal ON profile_targets.timestamp >= ltempbasal.start and profile_targets.timestamp < ltempbasal.end
ORDER BY 
  timestamp desc;
  ''');
