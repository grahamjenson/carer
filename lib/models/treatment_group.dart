// Non persisted combined model of Bolus and Carbs

import 'package:carer/mappers/sql/bolus.dart';
import 'package:carer/mappers/sql/carbs.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';

// Contains a bunch of treatments
class Treatment with DateMixin {
  Bolus? bolus;

  Carbs? carbs;

  @override
  DateTime get date {
    if (bolus != null) {
      return bolus!.date;
    } else {
      return carbs!.date;
    }
  }

  // can take either a bolus or a carb model
  Treatment(this.bolus, this.carbs)
      : assert(
          (bolus != null && carbs == null) || (bolus == null && carbs != null),
          'Either bolus or carbs must be non-null, but not both.',
        );

  String get treatmentStr {
    if (bolus != null) {
      return insulinStr;
    } else {
      return carbStr;
    }
  }

  String get insulinStr {
    if (bolus == null) {
      return "";
    }

    return '${toMax2dpStr(bolus!.value)}u';
  }

  String get carbStr {
    if (carbs == null) {
      return "";
    }

    return '${toMax2dpStr(carbs!.value)}g';
  }

  bool get isBolus => bolus != null;
  bool get isCarb => carbs != null;

  bool get isSmb => isBolus && bolus!.type == BolusType.smb;

  ////
  // Signals
  ////
  static ASignal<List<Treatment>> last2days = ASignal([], debugLabel: 'treatmentsLast2Days');
  static ASignal<List<Treatment>> lastSixHours = ASignal([], debugLabel: 'treatmentsLastSixHours');

  static setupSQLSignals() {
    var dependencies = [TimerService().minuteSignal, SQLToBolus().writeSignal, SQLToCarbs().writeSignal];
    signalAssign(lastSixHours, () async => _getLastTime(360), debugLabel: 'treatmentsLastSixHours', dependencies: dependencies);

    signalAssign(last2days, () async => _getLastTime(2880), debugLabel: 'treatmentsLast2days', dependencies: dependencies);
  }

  static Future<List<Treatment>> _getLastTime(int minsAgo) async {
    var carbs = await SQLToCarbs().lastMins(minsAgo);
    var bolus = await SQLToBolus().lastMins(minsAgo);
    List<Treatment> tl = [];

    for (var c in carbs) {
      if (c.value == 0) {
        continue;
      }
      tl.add(Treatment(null, c));
    }

    for (var b in bolus) {
      if (b.value == 0) {
        continue;
      }
      tl.add(Treatment(b, null));
    }

    tl.sort((a, b) => b.date.compareTo(a.date));
    return tl;
  }
}
