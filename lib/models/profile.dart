import 'package:carer/models/model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class ProfileRepository extends ModelRepository<Profile> {
  ProfileRepository() : super(profileTableName, timestampField: "start");

  @override
  Profile fromMap(Map<String, Object?> map) {
    List<int> carbratio = crKeys.map((key) => map[key] as int).toList();
    List<int> sens = isfKeys.map((key) => map[key] as int).toList();
    List<double> basal = basalKeys.map((key) => map[key] as double).toList();
    List<int> lowTarget = lowTargetKeys.map((key) => map[key] as int).toList();
    List<int> highTarget = highTargetKeys.map((key) => map[key] as int).toList();

    {
      return Profile(
        id: map["id"] as int?,
        name: map["name"] as String,
        eid: map["eid"] as String,
        startDate: DateTime.fromMillisecondsSinceEpoch(map["start"] as int),
        endDate: DateTime.fromMillisecondsSinceEpoch(map["end"] as int),
        dia: map["dia"] as int,
        units: map["units"] as String,
        timezone: map["timezone"] as String,
        carbratio: carbratio,
        sens: sens,
        basal: basal,
        lowTarget: lowTarget,
        highTarget: highTarget,
        duration: map["duration"] as int,
        source: map["source"] as String,
        percent: map["percent"] as int,
      );
    }
  }

  @override
  Map<String, Object> toSQLMap(Profile model) {
    Map<String, Object> map = {
      "name": model.name,
      "eid": model.eid!,
      "dia": model.dia,
      "units": model.units,
      "timezone": model.timezone,
      "start": model.startDate.millisecondsSinceEpoch,
      "duration": model.duration,
      "source": model.source,
      "percent": model.percent,
    };
    model.carbratio.asMap().forEach((index, value) {
      map[crKeys[index]] = value;
    });
    model.sens.asMap().forEach((index, value) {
      map[isfKeys[index]] = value;
    });
    model.basal.asMap().forEach((index, value) {
      map[basalKeys[index]] = value;
    });
    model.lowTarget.asMap().forEach((index, value) {
      map[lowTargetKeys[index]] = value;
    });
    model.highTarget.asMap().forEach((index, value) {
      map[highTargetKeys[index]] = value;
    });

    return map;
  }
}

class Profile extends DateRangeModel {
  static final ProfileRepository _q = ProfileRepository();

  @override
  ModelRepository get repository => _q;

  final int dia;
  final String name;
  final String units;
  final String timezone;

  final String source;

  final int percent;

  final List<int> carbratio;
  final List<int> sens;
  final List<double> basal;
  final List<int> lowTarget;
  final List<int> highTarget;

  Profile({
    super.id,
    required this.name,
    required super.eid,
    // Date Range
    required super.startDate,
    required super.endDate,
    required super.duration,
    // Profile
    required this.dia,
    required this.units,
    required this.timezone,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.lowTarget,
    required this.highTarget,
    required this.source,
    required this.percent,
  });

  factory Profile.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  get isTempProfile => duration != 0;

  static Future<int> saveAll(List<Profile> models) => _q.saveAll(models);

  static Future<Profile?> atTime(DateTime date) async {
    var ms = date.millisecondsSinceEpoch;
    return (await _q.query(conditions: {"start <= ?": ms, "end >= ?": ms}, limit: 1)).firstOrNull;
  }

  static Future<List<Profile>> after(DateTime date) async {
    return _q.query(conditions: {
      "end >= ?": date.millisecondsSinceEpoch,
    });
  }

  static Signal<int> get writeSignal => _q.writeSignal;

  static Future<Profile?> profile() async {
    return _q.query(limit: 1, name: "lastProfile").then((value) => value.firstOrNull);
  }

  static FutureSignal<Profile?> currentProfile = acomputedAsync(() async {
    alog("updating currentProfile");
    return await atTime(clock.now());
  }, null, debugLabel: 'currentProfile', dependencies: [writeSignal, TimerService().fifteenSecondSignal]);
}

const crKeys = [
  "cr0",
  "cr1",
  "cr2",
  "cr3",
  "cr4",
  "cr5",
  "cr6",
  "cr7",
  "cr8",
  "cr9",
  "cr10",
  "cr11",
  "cr12",
  "cr13",
  "cr14",
  "cr15",
  "cr16",
  "cr17",
  "cr18",
  "cr19",
  "cr20",
  "cr21",
  "cr22",
  "cr23"
];

const isfKeys = [
  "isf0",
  "isf1",
  "isf2",
  "isf3",
  "isf4",
  "isf5",
  "isf6",
  "isf7",
  "isf8",
  "isf9",
  "isf10",
  "isf11",
  "isf12",
  "isf13",
  "isf14",
  "isf15",
  "isf16",
  "isf17",
  "isf18",
  "isf19",
  "isf20",
  "isf21",
  "isf22",
  "isf23"
];

const basalKeys = [
  "basal0",
  "basal1",
  "basal2",
  "basal3",
  "basal4",
  "basal5",
  "basal6",
  "basal7",
  "basal8",
  "basal9",
  "basal10",
  "basal11",
  "basal12",
  "basal13",
  "basal14",
  "basal15",
  "basal16",
  "basal17",
  "basal18",
  "basal19",
  "basal20",
  "basal21",
  "basal22",
  "basal23"
];

const lowTargetKeys = [
  "tlow0",
  "tlow1",
  "tlow2",
  "tlow3",
  "tlow4",
  "tlow5",
  "tlow6",
  "tlow7",
  "tlow8",
  "tlow9",
  "tlow10",
  "tlow11",
  "tlow12",
  "tlow13",
  "tlow14",
  "tlow15",
  "tlow16",
  "tlow17",
  "tlow18",
  "tlow19",
  "tlow20",
  "tlow21",
  "tlow22",
  "tlow23"
];

const highTargetKeys = [
  "thigh0",
  "thigh1",
  "thigh2",
  "thigh3",
  "thigh4",
  "thigh5",
  "thigh6",
  "thigh7",
  "thigh8",
  "thigh9",
  "thigh10",
  "thigh11",
  "thigh12",
  "thigh13",
  "thigh14",
  "thigh15",
  "thigh16",
  "thigh17",
  "thigh18",
  "thigh19",
  "thigh20",
  "thigh21",
  "thigh22",
  "thigh23"
];
