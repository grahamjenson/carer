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

  List<TreatmentGroup> getWindows(int windowMins) {
    if (windowMins < 1) {
      return [];
    }

    DateTime now = clock.now();

    Duration windowDuration = Duration(minutes: windowMins);
    // This is the first Start time forthe groups
    DateTime startTime =
        startDate.subtract(Duration(minutes: startDate.minute % windowMins, seconds: startDate.second, milliseconds: startDate.millisecond));
    DateTime endTime = startTime.add(windowDuration);

    // This is pretty inefficient, but I dont think it is that bad
    // plus it works
    List<TreatmentGroup> treatments = [];
    while (startTime.isBefore(now)) {
      var tg = TreatmentGroup(startTime, endTime);
      var smbTG = TreatmentGroup(startTime, endTime, isSMBsOnly: true);

      treatments.insert(0, smbTG);
      treatments.insert(0, tg);

      for (var c in carbsModels) {
        tg.addCarbModel(c);
      }
      for (var b in bolusModels) {
        if (b.type == BolusType.smb) {
          smbTG.addBolusModel(b);
        } else {
          tg.addBolusModel(b);
        }
      }

      startTime = startTime.add(windowDuration);
      endTime = endTime.add(windowDuration);
    }

    treatments = treatments.where((t) => t.count > 0).toList();

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

class TreatmentGroup with DateMixin {
  DateTime startDate;
  late DateTime endDate;

  @override
  late DateTime date;

  List<Bolus> bolusModels = [];
  List<Carbs> carbsModels = [];

  bool isSMBsOnly;
  TreatmentGroup(this.startDate, this.endDate, {this.isSMBsOnly = false}) {
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

    if (isSMBsOnly) {
      return;
    }
    // Only add if carb model is between start and end date OR equal to endDate
    if ((model.date.isAfter(startDate) && (model.date.isBefore(endDate))) || model.date.isAtSameMomentAs(endDate)) {
      carbsModels.add(model);
      if (model.date.isAfter(date)) {
        date = model.date;
      }
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

    if (isSMBsOnly && model.type != BolusType.smb) {
      return;
    }
    // Only add if insulin model is between start and end date OR equal to endDate
    if (((model.date.isAfter(startDate) && model.date.isBefore(endDate))) || model.date.isAtSameMomentAs(endDate)) {
      bolusModels.add(model);
      if (model.date.isAfter(date)) {
        date = model.date;
      }
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
