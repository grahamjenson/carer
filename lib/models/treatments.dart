// Non persisted combined model of Bolus and Carbs
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';

class Treatment extends Model {
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

  static ASignal<List<Treatment>> lastSixHours = ASignal([], debugLabel: 'treatmentsLastSixHours');

  static setupSQLSignals() {
    signalAssign(lastSixHours, () => SQLToTreatment().lastMins(60 * 6),
        debugLabel: 'treatmentsLastSixHours', dependencies: [TimerService().minuteSignal, SQLToBolus().writeSignal, SQLToCarbs().writeSignal]);
  }
}
