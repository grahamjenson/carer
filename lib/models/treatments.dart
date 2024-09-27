// Non persisted combined model of Bolus and Carbs
import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class TreatmentList {
  final List<Bolus> bolusModels = [];
  final List<Carbs> carbsModels = [];

  // As late as it can be
  DateTime startDate = clock.now();
  // As early as it can be
  DateTime endDate = clock.now().subtract(const Duration(days: 365));

  TreatmentList();

  void addCarbModel(Carbs model) {
    if (model.value == 0) {
      return;
    }
    carbsModels.add(model);
    _updateDate(model.date);
  }

  void addBolusModel(Bolus model) {
    if (model.value == 0) {
      return;
    }
    bolusModels.add(model);
    _updateDate(model.date);
  }

  void _updateDate(DateTime date) {
    if (date.isBefore(startDate)) {
      startDate = date;
    }
    if (date.isAfter(endDate)) {
      endDate = date;
    }
  }

  List<Treatment> getWindows(int windowMins) {
    Map<int, Treatment> timeBuckets = {};
    DateTime now = clock.now();

    Duration windowDuration = Duration(minutes: windowMins);
    DateTime startTime = now.subtract(Duration(minutes: now.minute % windowMins, seconds: now.second, milliseconds: now.millisecond));
    DateTime endTime = startTime.add(windowDuration);

    var numberOfBuckets = clock.now().difference(startDate).inMinutes / windowMins;

    var treatment = Treatment(startTime, endTime);
    timeBuckets[treatment.bucketFor(windowMins)] = treatment;

    for (var i = 0; i < numberOfBuckets + 2; i++) {
      startTime = startTime.subtract(windowDuration);
      endTime = endTime.subtract(windowDuration);
      treatment = Treatment(startTime, endTime);
      timeBuckets[treatment.bucketFor(windowMins)] = treatment;
    }

    for (var c in carbsModels) {
      timeBuckets[c.bucketFor(windowMins)]!.addCarbModel(c);
    }

    for (var b in bolusModels) {
      timeBuckets[b.bucketFor(windowMins)]!.addBolusModel(b);
    }
    var treatments = timeBuckets.values.where((t) => t.count > 0).toList();

    return treatments;
  }

  ////
  // Signals
  ////
  static ASignal<TreatmentList> last2days = ASignal(TreatmentList(), debugLabel: 'treatmentsLast2Days');
  static ASignal<TreatmentList> lastSixHours = ASignal(TreatmentList(), debugLabel: 'treatmentsLastSixHours');

  static setupSQLSignals() {
    var dependencies = [TimerService().minuteSignal, SQLToBolus().writeSignal, SQLToCarbs().writeSignal];
    signalAssign(lastSixHours, () async => _getLastTime(360), debugLabel: 'treatmentsLastSixHours', dependencies: dependencies);

    signalAssign(last2days, () async => _getLastTime(2880), debugLabel: 'treatmentsLast2days', dependencies: dependencies);
  }

  static Future<TreatmentList> _getLastTime(int minsAgo) async {
    var carbs = await SQLToCarbs().lastMins(minsAgo);
    var bolus = await SQLToBolus().lastMins(minsAgo);
    var tl = TreatmentList();

    for (var c in carbs) {
      tl.addCarbModel(c);
    }

    for (var b in bolus) {
      tl.addBolusModel(b);
    }
    return tl;
  }
}

class Treatment with DateMixin {
  DateTime startDate;
  late DateTime endDate;

  @override
  late DateTime date;

  List<Bolus> bolusModels = [];
  List<Carbs> carbsModels = [];

  Treatment(this.startDate, this.endDate) {
    date = startDate;
  }

  @override
  int get minuteTimestamp => startDate.millisecondsSinceEpoch ~/ 60000;
  @override
  int bucketFor(int window) => minuteTimestamp - (minuteTimestamp % window);

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
}
