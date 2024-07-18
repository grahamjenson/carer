// Non persisted combined model of Bolus and Carbs
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';
import 'package:signals/signals_flutter.dart';

class TreatmentRepository extends ModelRepository<Treatment> {
  TreatmentRepository() : super(concatTreatmentsTableName, timestampField: "max_ts");

  @override
  Treatment fromMap(Map<String, Object?> map) {
    var requiredKeys = ["count", "max_ts"];
    if (!(validateNotNull(map, requiredKeys) &&
        validateType(map, [
          ("count", int),
          ("max_ts", int),
          ("carbs", int),
          ("insulin", double),
        ]))) {
      throw ArgumentError("Invalid Treatment Map: $map");
    }

    {
      return Treatment(
        count: map["count"] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map["max_ts"] as int),
        carbs: map["carbs"] as int?,
        insulin: map["insulin"] as double?,
      );
    }
  }

  @override
  Map<String, Object> toSQLMap(Treatment model) {
    Map<String, Object> map = {
      "count": model.count,
      "max_ts": model.date.millisecondsSinceEpoch,
    };
    if (model.carbs != null) {
      map["carbs"] = model.carbs!;
    }
    if (model.insulin != null) {
      map["insulin"] = model.insulin!;
    }
    return map;
  }
}

class Treatment extends Model {
  static final TreatmentRepository _q = TreatmentRepository();

  @override
  ModelRepository get repository => _q;

  @override
  DateTime date;
  double? insulin;
  int? carbs;
  int count;

  Treatment({required this.date, this.insulin, this.carbs, this.count = 1});

  bool get isConcated => count > 1;

  @override
  Duration get age {
    return clock.now().difference(date);
  }

  int get minsAgo => (clock.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch) ~/ 60000;

  String get insulinStr {
    if (insulin != null && insulin != 0) {
      return '${toMax2dp(insulin!)}u';
    } else {
      return "";
    }
  }

  String get carbStr {
    if (carbs != null && carbs != 0) {
      return '${toMax2dp(carbs!)}g';
    } else {
      return "";
    }
  }

  static Future<List<Treatment>> lastMins(int minsAgo) => _q.lastMins(minsAgo);

  ////
  // Future Signals
  ////

  static FutureSignal<List<Treatment>> lastSixHours = acomputedAsync(() async {
    alog("updating Treatments lastSixHours");
    // Needs to update every minute to get latest results.
    var t = TimerService().minuteSignal.value;
    var b = Bolus.writeSignal.value;
    var c = Carbs.writeSignal.value;
    return Treatment.lastMins(60 * 6);
  }, [], debugLabel: 'treatmentsLastSixHours');
}
