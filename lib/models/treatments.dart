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

  @override
  int get minuteTimestamp => startDate.millisecondsSinceEpoch ~/ 60000;
  @override
  int get fiveMinsBucket => minuteTimestamp - (minuteTimestamp % 5);

  void addCarbModel(Carbs model) {
    if (model.value == 0) {
      return;
    }

    // Only add if carb model is between start and end date OR equal to endDate
    if ((model.date.isAfter(startDate) && (model.date.isBefore(endDate))) || model.date.isAtSameMomentAs(endDate)) {
      carbsModels.add(model);
    }

    if (model.date.isAfter(date)) {
      date = model.date;
    }
  }

  @override
  String toString() {
    if (count == 0) {
      return 'Treatment{empty}';
    }
    return 'Treatment{boluses: ${bolusModels.length}, carbs: ${carbsModels.length}';
  }

  void addBolusModel(Bolus model) {
    if (model.value == 0) {
      return;
    }

    // Only add if insulin model is between start and end date OR equal to endDate
    if (((model.date.isAfter(startDate) && model.date.isBefore(endDate))) || model.date.isAtSameMomentAs(endDate)) {
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

  static ASignal<List<Treatment>> last2days = ASignal([], debugLabel: 'treatmentsLast2Days');
  static ASignal<List<Treatment>> lastSixHours = ASignal([], debugLabel: 'treatmentsLastSixHours');

  static _getLastTime(int minsAgo) async {
    var carbs = await SQLToCarbs().lastMins(minsAgo);
    var bolus = await SQLToBolus().lastMins(minsAgo);

    // group and total all carbs and boluses to 5 minute windows that is based on hour,
    // e.g. 12:00:00 - 12:04:59, 12:05:00 - 12:09:59, 12:10:00 - 12:14:59

    // This is in minutes since epoch
    Map<int, Treatment> timeBuckets = {};
    DateTime now = clock.now();
    DateTime fiveMinutes = now.subtract(Duration(minutes: now.minute % 5, seconds: now.second, milliseconds: now.millisecond));

    var numberOfBuckets = minsAgo / 5;
    for (var i = 0; i < numberOfBuckets + 2; i++) {
      var time = fiveMinutes.subtract(Duration(minutes: i * 5));
      var treatment = Treatment(time);
      timeBuckets[treatment.fiveMinsBucket] = Treatment(time);
    }

    for (var c in carbs) {
      timeBuckets[c.fiveMinsBucket]!.addCarbModel(c);
    }

    for (var b in bolus) {
      timeBuckets[b.fiveMinsBucket]!.addBolusModel(b);
    }
    var treatments = timeBuckets.values.where((t) => t.count > 0).toList();

    return treatments;
  }

  static setupSQLSignals() {
    var dependencies = [TimerService().minuteSignal, SQLToBolus().writeSignal, SQLToCarbs().writeSignal];
    signalAssign(lastSixHours, () async => await _getLastTime(360), debugLabel: 'treatmentsLastSixHours', dependencies: dependencies);

    signalAssign(last2days, () async => await _getLastTime(2880), debugLabel: 'treatmentsLast2days', dependencies: dependencies);
  }
}
