import 'package:carer/models/model.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';

class ValueAtTimeRepository extends ModelRepository<ValueAtTime> {
  ValueAtTimeRepository() : super(valuesAtTimeTableName);

  @override
  ValueAtTime fromMap(Map<String, Object?> map) {
    var requiredKeys = ["timestamp", "lowTarget", "highTarget", "isTempTarget", "basal", "isTempBasal"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, [
          ("eid", String),
          ("timestamp", int),
          ("lowTarget", int),
          ("highTarget", int),
          ("basal", double),
          ("isf", int),
          ("cr", int),
          ("isTempProfile", int),
          ("isTempTarget", int),
          ("isTempBasal", int),
          ("profileName", String),
        ]))) {
      throw ArgumentError("Invalid ValueAtTime Map: $map");
    }

    return ValueAtTime(
      eid: "${map["eid"]}",
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      lowTarget: map["lowTarget"] as int,
      highTarget: map["highTarget"] as int,
      basal: map["basal"] as double,
      isf: map["isf"] as int,
      cr: map["cr"] as int,
      isTempProfile: map["isTempProfile"] == 1,
      isTempBasal: map["isTempBasal"] == 1,
      isTempTarget: map["isTempTarget"] == 1,
      profileName: map["profileName"] as String,
    );
  }

  @override
  Map<String, Object> toSQLMap(ValueAtTime model) {
    return {
      "eid": model.eid!,
      "timestamp": model.date.millisecondsSinceEpoch,
      //
      "lowTarget": model.lowTarget,
      "highTarget": model.highTarget,
      //
      "basal": model.basal,
      "isf": model.isf,
      "cr": model.cr,
      //
      "profileName": model.profileName,
      //
      "isTempProfile": model.isTempProfile ? 1 : 0,
      "isTempBasal": model.isTempBasal ? 1 : 0,
      "isTempTarget": model.isTempTarget ? 1 : 0,
    };
  }
}

class ValueAtTime extends Model {
  static final ValueAtTimeRepository _q = ValueAtTimeRepository();

  @override
  ModelRepository get repository => _q;

  @override
  final DateTime date;

  final int lowTarget;
  final int highTarget;

  final double basal;
  final int isf;
  final int cr;

  final String profileName;

  final bool isTempBasal;
  final bool isTempTarget;
  final bool isTempProfile;

  ValueAtTime({
    required super.eid,
    required this.date,
    required this.lowTarget,
    required this.highTarget,
    required this.isTempTarget,
    required this.basal,
    required this.isTempBasal,
    required this.isf,
    required this.cr,
    required this.profileName,
    required this.isTempProfile,
  });

  factory ValueAtTime.fromMap(Map<String, dynamic> map) {
    return _q.fromMap(map);
  }

  int get minsAgo => (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/ 60000;

  static Future<List<ValueAtTime>> query({
    int? after,
    int? before,
    Map<String, Object>? conditions,
    int? limit,
  }) {
    return _q.query(before: before, after: after, limit: limit, conditions: conditions);
  }

  static Future<List<ValueAtTime>> lastMins(int minsAgo) => _q.lastMins(minsAgo);
  static Future<int> saveAll(List<ValueAtTime> models) => _q.saveAll(models);
  static Future<int> upsertAll(List<ValueAtTime> models) => _q.upsertAll(models);

  static FutureSignal<List<ValueAtTime>> lastSixHours = acomputedAsync(() async {
    alog("updating ValueAtTime lastSixHours");
    var _ = updateValues.value; // Update every write to this table
    return await ValueAtTime.lastMins(60 * 6);
  }, [], debugLabel: 'valueAtTimeLastSixHours');

  static FutureSignal<int> updateValues = acomputedAsync(() async {
    var now = clock.now();
    // rounded to nearest minute
    now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    var start = now.subtract(const Duration(hours: 6));

    var profiles = await Profile.after(start);
    var tempTargets = await TempTarget.after(start);
    var tempBasals = await TempBasal.after(start);

    // go over the last 6 hours and for every minute generate a new ValueAtTime
    List<ValueAtTime> vats = [];
    for (var i = 0; i < 360; i++) {
      var d = now.subtract(Duration(minutes: i));
      vats.add(createValueAtTime(profiles, tempTargets, tempBasals, d));
    }
    var ret = ValueAtTime.upsertAll(vats);

    alog("updated $ret ValueAtTime entries");

    return ret;
  }, 0, debugLabel: 'updateValueAtTime', dependencies: [
    TimerService().minuteSignal,
    Profile.writeSignal,
    TempBasal.writeSignal,
    TempTarget.writeSignal,
  ]);

  static ValueAtTime createValueAtTime(List<Profile> profiles, List<TempTarget> tempTargets, List<TempBasal> tempBasals, DateTime date) {
    int hourOfDay = date.hour;
    int minutesSinceEpoch = date.millisecondsSinceEpoch ~/ 60000;

    // make date rounded to nearest minute
    fon(DateRangeModel element) => element.isAtTime(date);
    Profile? profile = profiles.firstWhereOrNull(fon);
    TempBasal? tempBasal = tempBasals.firstWhereOrNull(fon);
    TempTarget? tempTarget = tempTargets.firstWhereOrNull(fon);

    int lowTarget = tempTarget?.lowTarget ?? profile?.lowTarget[hourOfDay] ?? 0;
    int highTarget = tempTarget?.highTarget ?? profile?.highTarget[hourOfDay] ?? 0;

    double basal = tempBasal?.value ?? profile?.basal[hourOfDay] ?? 0;
    int isf = profile?.sens[hourOfDay] ?? 0;
    int cr = profile?.carbratio[hourOfDay] ?? 0;
    String profileName = profile?.name ?? "";

    bool isTempProfile = profile?.isTempProfile ?? false;
    bool isTempBasal = tempBasal != null;
    bool isTempTarget = tempTarget != null;

    ValueAtTime v = ValueAtTime(
      eid: "MSE-$minutesSinceEpoch",
      date: date,
      lowTarget: lowTarget,
      highTarget: highTarget,
      isTempTarget: isTempTarget,
      basal: basal,
      isTempBasal: isTempBasal,
      isf: isf,
      cr: cr,
      profileName: profileName,
      isTempProfile: isTempProfile,
    );

    return v;
  }
}
