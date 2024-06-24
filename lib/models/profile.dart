import 'package:carer/models/model.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:signals/signals_flutter.dart';

class ProfileRepository extends ModelRepository<Profile> {
  ProfileRepository() : super(profileTableName);

  @override
  Profile fromMap(Map<String, Object?> map) {
    List<int> carbratio = crKeys.map((key) => map[key] as int).toList();
    List<int> sens = isfKeys.map((key) => map[key] as int).toList();
    List<double> basal = basalKeys.map((key) => map[key] as double).toList();
    List<int> targetLow = targetLowKeys.map((key) => map[key] as int).toList();
    List<int> targetHigh =
        targetHighKeys.map((key) => map[key] as int).toList();

    {
      return Profile(
        id: map["id"] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
        dia: map["dia"] as int,
        units: map["units"] as String,
        timezone: map["timezone"] as String,
        carbratio: carbratio,
        sens: sens,
        basal: basal,
        targetLow: targetLow,
        targetHigh: targetHigh,
      );
    }
  }

  @override
  Map<String, Object> toSQLMap(Profile model) {
    Map<String, Object> map = {
      "dia": model.dia,
      "units": model.units,
      "timezone": model.timezone,
      "timestamp": model.date.millisecondsSinceEpoch,
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
    model.targetLow.asMap().forEach((index, value) {
      map[targetLowKeys[index]] = value;
    });
    model.targetHigh.asMap().forEach((index, value) {
      map[targetHighKeys[index]] = value;
    });

    return map;
  }
}

class Profile extends Model {
  static final ProfileRepository _q = ProfileRepository();

  @override
  ModelRepository get repository => _q;

  @override
  int? id;

  @override
  final DateTime date;
  final int dia;
  final String units;
  final String timezone;

  final List<int> carbratio;
  final List<int> sens;
  final List<double> basal;
  final List<int> targetLow;
  final List<int> targetHigh;

  Profile({
    this.id,
    required this.date,
    required this.dia,
    required this.units,
    required this.timezone,
    required this.carbratio,
    required this.sens,
    required this.basal,
    required this.targetLow,
    required this.targetHigh,
  });

  factory Profile.fromMap(Map<String, Object?> map) {
    return _q.fromMap(map);
  }

  static Future<double> basalAtTime(DateTime date) async {
    var tb = await TempBasal.atTime(date);
    if (tb != null) {
      return tb.value;
    }
    var profile = await Profile.profile();
    if (profile == null) {
      return 0;
    }
    return profile.basal[date.hour];
  }

  static Future<(int, int)> targetAtTime(DateTime date) async {
    var tt = await TempTarget.atTime(date);
    if (tt != null) {
      return (tt.targetHigh, tt.targetLow);
    }
    var profile = await Profile.profile();
    if (profile == null) {
      return (0, 0);
    }

    return (profile.targetLow[date.hour], profile.targetHigh[date.hour]);
  }

  static Future<Profile?> profile() async {
    return (await _q.query(limit: 1)).firstOrNull;
  }

  static Future<int?> count(
      {int? after, int? before, Map<String, Object>? conditions}) async {
    return _q.count(after: after, before: before, conditions: conditions);
  }

  static Signal<int> get writeSignal => _q.writeSignal;
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

const targetLowKeys = [
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

const targetHighKeys = [
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
