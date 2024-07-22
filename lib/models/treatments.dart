// Non persisted combined model of Bolus and Carbs
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/sql/sqlmodel.dart';
import 'package:carer/sql/statements/carer_db_tables.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class TreatmentRepository extends ModelRepository<Treatment> {
  TreatmentRepository() : super(concatTreatmentsViewName, timestampField: "max_ts");

  @override
  Treatment fromMap(Map<String, Object?> map) {
    return SQLToTreatment().aToB(SQLRow(map));
  }

  @override
  Map<String, Object> toSQLMap(Treatment model) {
    throw UnimplementedError();
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
