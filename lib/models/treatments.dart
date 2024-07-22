// Non persisted combined model of Bolus and Carbs
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/math.dart';
import 'package:signals/signals_flutter.dart';

class Treatment extends Model {
  @override
  ModelRepository get repository => throw UnimplementedError();

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

  ////
  // Future Signals
  ////

  static FutureSignal<List<Treatment>> lastSixHours = acomputedAsync(
    () async {
      alog("updating Treatments lastSixHours");
      // Needs to update every minute to get latest results.
      TimerService().minuteSignal.value;
      SQLToBolus().writeSignal.value;
      SQLToCarbs().writeSignal.value;
      return SQLToTreatment().lastMins(60 * 6);
    },
    [],
    debugLabel: 'treatmentsLastSixHours',
  );
}
