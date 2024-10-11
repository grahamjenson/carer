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
  alarmLogsTable,
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
      
      -- VIRTUAL
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,
      minute_timestamp INTEGER GENERATED ALWAYS AS (timestamp / 60000) VIRTUAL,

      -- CONTRAINTS
      UNIQUE(eid)
    )
  ''');

const String bolusTableName = 'bolus';
const bolusTable = DBTable(bolusTableName, '''
    CREATE TABLE bolus (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      value REAL,
      type TEXT,
      timestamp INTEGER,

      -- VIRTUAL
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,

      -- CONTRAINTS
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

      -- VIRTUAL
      datetime TEXT GENERATED ALWAYS AS (datetime(timestamp / 1000, 'unixepoch')) VIRTUAL,


      -- CONTRAINTS
      UNIQUE(eid)
    )
  ''');

const String tempbasalTableName = 'tempbasal';
const tempbasalTable = DBTable(tempbasalTableName, '''
    CREATE TABLE tempbasal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      start INTEGER,
      duration INTEGER,
      value REAL,

      -- VIRTUAL
      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,
      

      -- CONTRAINTS
      UNIQUE(eid)
    )
  ''');

const String temptargetsTableName = 'temptargets';
const temptargetsTable = DBTable(temptargetsTableName, '''
    CREATE TABLE temptargets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eid TEXT,
      start INTEGER,
      duration INTEGER,
      highTarget INTEGER,
      lowTarget INTEGER,

      -- VIRTUAL
      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      end INTEGER GENERATED ALWAYS AS (start + (duration * 1000)) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL,


      -- CONTRAINTS
      UNIQUE(eid)
    )
  ''');

const String alarmLogsTableName = 'alarm_logs';
const alarmLogsTable = DBTable(alarmLogsTableName, '''
    CREATE TABLE alarm_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT,
      conditions TEXT,
      stage TEXT, -- Like pending, alerting
      start INTEGER,
      end INTEGER,

      -- VIRTUAL

      timestamp INTEGER GENERATED ALWAYS AS (start) VIRTUAL,
      starttime TEXT GENERATED ALWAYS AS (datetime(start / 1000, 'unixepoch')) VIRTUAL,
      endtime TEXT GENERATED ALWAYS AS (datetime(end / 1000, 'unixepoch')) VIRTUAL
      
      

      -- CONTRAINTS
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


      -- CONTRAINTS
      UNIQUE(eid)
    )
  ''');
