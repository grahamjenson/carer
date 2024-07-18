import 'package:carer/models/model.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class ValueAtTimeRepository extends ModelRepository<ValueAtTime> {
  ValueAtTimeRepository() : super(valuesAtTimeTableName);

  @override
  ValueAtTime fromMap(Map<String, Object?> map) {
    var requiredKeys = ["timestamp", "lowTarget", "highTarget", "isTempTarget", "basal", "isTempBasal"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, [
          ("timestamp", int),
          ("lowTarget", int),
          ("highTarget", int),
          ("basal", double),
          ("isf", double),
          ("cr", double),
          ("isTempProfile", int),
          ("isTempTarget", int),
          ("isTempBasal", int),
          ("profileName", String),
        ]))) {
      throw ArgumentError("Invalid Target Map: $map");
    }

    return ValueAtTime(
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"] as int),
      lowTarget: map["lowTarget"] as int,
      highTarget: map["highTarget"] as int,
      basal: map["basal"] as double,
      isf: map["isf"] as double,
      cr: map["cr"] as double,
      isTempProfile: map["isTempProfile"] == 1,
      isTempBasal: map["isTempBasal"] == 1,
      isTempTarget: map["isTempTarget"] == 1,
      profileName: map["profileName"] as String,
    );
  }

  @override
  Map<String, Object> toSQLMap(ValueAtTime model) {
    return {
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
  final double isf;
  final double cr;

  final String profileName;

  final bool isTempBasal;
  final bool isTempTarget;
  final bool isTempProfile;

  ValueAtTime({
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

  static FutureSignal<List<ValueAtTime>> lastSixHours = acomputedAsync(() async {
    alog("updating ValueAtTime lastSixHours");
    var _ = TimerService().minuteSignal.value; // Update eevry minute
    var b = TempTarget.writeSignal.value;
    var c = TempBasal.writeSignal.value;
    var d = Profile.writeSignal.value;
    return await ValueAtTime.lastMins(60 * 6);
  }, [], debugLabel: 'valueAtTimeLastSixHours');
}
