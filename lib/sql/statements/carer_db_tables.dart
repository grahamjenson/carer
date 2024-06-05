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
  profileChangeTimesView,
  profileHourView,
  tempTargetAtTime,
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
      UNIQUE(start, value)
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

      targetTop INTEGER,
      targetBottom INTEGER,
      UNIQUE(start, targetTop, targetBottom)
    )
  ''');

// TODO this doesnt work because you could have profile1 -> profile2 -> profile1 which would mean profile 1 has multiple start stop dates
// TODO need to find real start and stop dates for profiles to properly find real start/stop dates on them.
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
    b as  (SELECT  timestamp, value as insulin FROM bolus) ,
    c as  (SELECT timestamp, value as carbs from carbs),
    x AS (SELECT b.timestamp, b.insulin, null as carbs  from b UNION SELECT c.timestamp, null as insulin, c.carbs from c)
    SELECT * from x ORDER by timestamp desc
  ''');

const String concatTreatmentsTableName = 'concatTreatments';
const concatTreatmentsView = DBTable(concatTreatmentsTableName, '''
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
const String sgvsCleanViewTableName = 'sgvsClean';
const sgvsCleanView = DBTable(sgvsCleanViewTableName, '''
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

// Profile hour table, each profile is exploded into the values they provide each hour

const String profileHourViewName = "profileHourView";
const profileHourView = DBTable(profileHourViewName, '''
 CREATE VIEW profileHourView AS
with hours(hour) as (
  values
    (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),
    (12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23)
)
select id, hour, timestamp, datetime, dia, units, timezone,
CASE hour 
	when 0 then cr0
  when 1 then cr1
  when 2 then cr2
  when 3 then cr3
	when 4 then cr4
  when 5 then cr5
  when 6 then cr6
  when 7 then cr7
	when 8 then cr8
  when 9 then cr9
  when 10 then cr10
  when 11 then cr11
	when 12 then cr12
  when 13 then cr13
  when 14 then cr14
  when 15 then cr15
	when 16 then cr16
  when 17 then cr17
  when 18 then cr18
  when 19 then cr19
	when 20 then cr20
  when 21 then cr21
  when 22 then cr22
  when 23 then cr23
end cr,
CASE hour 
	when 0 then isf0
  when 1 then isf1
  when 2 then isf2
  when 3 then isf3
	when 4 then isf4
  when 5 then isf5
  when 6 then isf6
  when 7 then isf7
	when 8 then isf8
  when 9 then isf9
  when 10 then isf10
  when 11 then isf11
	when 12 then isf12
  when 13 then isf13
  when 14 then isf14
  when 15 then isf15
	when 16 then isf16
  when 17 then isf17
  when 18 then isf18
  when 19 then isf19
	when 20 then isf20
  when 21 then isf21
  when 22 then isf22
  when 23 then isf23
end isf,
CASE hour 
	when 0 then basal0
  when 1 then basal1
  when 2 then basal2
  when 3 then basal3
	when 4 then basal4
  when 5 then basal5
  when 6 then basal6
  when 7 then basal7
	when 8 then basal8
  when 9 then basal9
  when 10 then basal10
  when 11 then basal11
	when 12 then basal12
  when 13 then basal13
  when 14 then basal14
  when 15 then basal15
	when 16 then basal16
  when 17 then basal17
  when 18 then basal18
  when 19 then basal19
	when 20 then basal20
  when 21 then basal21
  when 22 then basal22
  when 23 then basal23
end basal,
CASE hour 
	when 0 then tlow0
  when 1 then tlow1
  when 2 then tlow2
  when 3 then tlow3
	when 4 then tlow4
  when 5 then tlow5
  when 6 then tlow6
  when 7 then tlow7
	when 8 then tlow8
  when 9 then tlow9
  when 10 then tlow10
  when 11 then tlow11
	when 12 then tlow12
  when 13 then tlow13
  when 14 then tlow14
  when 15 then tlow15
	when 16 then tlow16
  when 17 then tlow17
  when 18 then tlow18
  when 19 then tlow19
	when 20 then tlow20
  when 21 then tlow21
  when 22 then tlow22
  when 23 then tlow23
end tlow,
CASE hour 
	when 0 then thigh0
  when 1 then thigh1
  when 2 then thigh2
  when 3 then thigh3
	when 4 then thigh4
  when 5 then thigh5
  when 6 then thigh6
  when 7 then thigh7
	when 8 then thigh8
  when 9 then thigh9
  when 10 then thigh10
  when 11 then thigh11
	when 12 then thigh12
  when 13 then thigh13
  when 14 then thigh14
  when 15 then thigh15
	when 16 then thigh16
  when 17 then thigh17
  when 18 then thigh18
  when 19 then thigh19
	when 20 then thigh20
  when 21 then thigh21
  when 22 then thigh22
  when 23 then thigh23
end thigh
from 
	hours join profile;
''');

// This is a list of timestamps where the profile may have changed in the last couple days.
// TODO, expand the days for things like autotune
const String profileChangeTimesViewName = "profileChangeTimesView";
const profileChangeTimesView = DBTable(profileChangeTimesViewName, '''
CREATE VIEW profileChangeTimesView AS
    with hours(hour) as (
      values
        (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),
        (12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23)
    ),
    days(day) as (values (0),(1),(2)),
    start_of_hour(soh, tfhour) as (values (
      strftime('%s', datetime(strftime('%Y-%m-%d %H:00:00', 'now'))) * 1000, strftime('%H', 'now', 'localtime'))
    ),
    times as (
      select
        soh - ((days.day*24 + hours.hour) * 60 * 60 * 1000) as timestamp,
        datetime((soh - ((days.day*24 + hours.hour) * 60 * 60 * 1000))/1000, 'unixepoch') as datetime,
        cast(MOD(tfhour - (days.day*24 + hours.hour) + 24*30 ,24) as int) as hour
      from days join hours join start_of_hour
      )
    select * from times;
''');

// this takes all temptarget start and endtiems as that is when things change.
const String tempTargetAtTimeNAme = "tempTargetAtTime";
const tempTargetAtTime = DBTable(tempTargetAtTimeNAme, '''
CREATE VIEW tempTargetAtTime AS
    with 
    temptargettime as (
      select start as timestamp from temptargets union select end+1 as timestamp from temptargets
    ),
    temptargetchanges as (
      select 
			timestamp, 
			datetime(timestamp/1000, 'unixepoch') as datetime,
			strftime('%H', datetime(timestamp/1000, 'unixepoch'), 'localtime') as hour
        from temptargettime
    ),
    alldates as (select * from temptargetchanges union select * from profileChangeTimesView),
	current_profile as (select id from profile order by timestamp desc limit 1),
	profile_hours as (select * from current_profile join profileHourView on current_profile.id = profileHourView.id),
	profile_targets as (select alldates.timestamp, alldates.datetime, alldates.hour, profile_hours.tlow as profile_low, profile_hours.thigh as profile_high from alldates left join profile_hours on profile_hours.hour = alldates.hour)
	select * from profile_targets order by timestamp desc;
  ''');
