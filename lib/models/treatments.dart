// Non persisted combined model of Bolus and Carbs
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class Treatment with DateMixin {
  DateTime startDate;
  late DateTime endDate;

  @override
  late DateTime date;

  List<Bolus> bolusModels = [];
  List<Carbs> carbsModels = [];

  Treatment(this.startDate) {
    endDate = startDate.add(const Duration(minutes: 5));
    date = startDate;
  }

  void addCarbModel(Carbs model) {
    if (model.value == 0) {
      return;
    }
    // Only add if carb model is between start and end date OR equal to endDate
    if ((model.date.isAfter(startDate) && model.date.isBefore(endDate)) || model.date.isAtSameMomentAs(endDate)) {
      carbsModels.add(model);
    }
    if (model.date.isAfter(date)) {
      date = model.date;
    }
  }

  void addBolusModel(Bolus model) {
    if (model.value == 0) {
      return;
    }
    // Only add if insulin model is between start and end date OR equal to endDate
    if ((model.date.isAfter(startDate) && model.date.isBefore(endDate)) || model.date.isAtSameMomentAs(endDate)) {
      bolusModels.add(model);
    }
    if (model.date.isAfter(date)) {
      date = model.date;
    }
  }

  int get count => bolusModels.length + carbsModels.length;
  double get insulin => bolusModels.fold(0, (prev, element) => prev + element.value);
  double get carbs => carbsModels.fold(0, (prev, element) => prev + element.value);
  bool get isConcated => count > 1;

  String get insulinStr {
    if (insulin != 0) {
      return '${toMax2dp(insulin)}u';
    } else {
      return "";
    }
  }

  String get carbStr {
    if (carbs != 0) {
      return '${toMax2dp(carbs)}g';
    } else {
      return "";
    }
  }

  ////
  // Future Signals
  ////

  static ASignal<List<Treatment>> lastSixHours = ASignal([], debugLabel: 'treatmentsLastSixHours');

  static setupSQLSignals() {
    signalAssign(lastSixHours, () async {
      var carbs = await SQLToCarbs().lastMins(360);
      var bolus = await SQLToBolus().lastMins(360);

      print("Carbs: ${carbs.length}, Bolus: ${bolus.length}");
      // group and total all carbs and boluses to 5 minute windows that is based on hour,
      // e.g. 12:00:00 - 12:04:59, 12:05:00 - 12:09:59, 12:10:00 - 12:14:59

      // This is in minutes since epoch
      Map<int, Treatment> timeBuckets = {};
      DateTime now = clock.now();
      DateTime fiveMinutes = now.subtract(Duration(minutes: now.minute % 5, seconds: now.second, milliseconds: now.millisecond));

      for (var i = 0; i < 73; i++) {
        var time = fiveMinutes.subtract(Duration(minutes: i * 5));
        var treatment = Treatment(time);
        timeBuckets[treatment.fiveMinsAgoBucket] = Treatment(time);
      }

      for (var c in carbs) {
        timeBuckets[c.fiveMinsAgoBucket]!.addCarbModel(c);
      }

      for (var b in bolus) {
        timeBuckets[b.fiveMinsAgoBucket]!.addBolusModel(b);
      }

      return timeBuckets.values.toList().where((t) => t.count > 0).toList();
      // merge two lists
    }, debugLabel: 'treatmentsLastSixHours', dependencies: [TimerService().minuteSignal, SQLToBolus().writeSignal, SQLToCarbs().writeSignal]);
  }
}
