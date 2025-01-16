// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:carer/models/model.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

const MIN_BEFORE_MINS = 3;
const LAG_WIGGLE_DURATION = Duration(seconds: 30);

class CleanSGV extends ASGV with DateMixin {
  @override
  final int value;

  @override
  final DateTime date;

  CleanSGV? before; // previous SVGs ID

  // Create a list by following before
  List<CleanSGV> beforeN(int n) {
    var list = [this];
    var before = this.before;
    for (var i = 0; i < n; i++) {
      if (before == null) {
        break;
      }
      list.add(before);
      before = before.before;
    }
    return list;
  }

  CleanSGV(
    this.value,
    this.date, {
    this.before,
  });

  int? get rate5m {
    if (before == null) {
      return null;
    }
    return ((diff! / (minuteTimestamp - before!.minuteTimestamp)) * 5).toInt();
  }

  @override
  Range5 get range => targetRange(value);

  @override
  bool get isUrgentLow => range == Range5.veryLow;
  @override
  bool get isLow => range == Range5.low;
  @override
  bool get isNormal => range == Range5.mid;
  @override
  bool get isHigh => range == Range5.high;
  @override
  bool get isUrgentHigh => range == Range5.veryHigh;

  Range5 get diffRange {
    var fastDrop = TargetSettings().fastDropDelta;
    var fastRise = TargetSettings().fastRiseDelta;
    var diff = rate5m ?? 0;
    return range5(fastDrop, fastDrop * 0.8, fastRise * 0.8, fastRise, diff.toDouble());
  }

  int? get diff {
    if (before == null) {
      return null;
    }
    return value - before!.value;
  }

  @override
  String sgvStr() {
    return UISettings().unit.str(value);
  }

  String rate5mWithSign() {
    var unit = UISettings().unit;
    var diffPer5Mins = rate5m ?? 0;
    var sgv = unit.val(diffPer5Mins);
    var sgvStr = sgv.toStringAsFixed(1);
    if (sgv == 0) {
      sgvStr = "+0";
    } else if (sgv > 0) {
      sgvStr = "+${sgv.toStringAsFixed(1)}";
    }
    return sgvStr;
  }

  @override
  String toString() {
    return "SGV($value@${date.hour}:${date.minute})";
  }

  bool get withinLast3Hours => date.isAfter(clock.now().subtract(const Duration(hours: 3)));

  bool get withinRange => value > TargetSettings().lowTarget && value < TargetSettings().highTarget;

  // Hardcoded cached prediction list
  List<CleanSGV?>? predictions;
  void setPredictions(List<CleanSGV?> predictions) {
    if (this.predictions != null) {
      // Do not update predictions,
      // TODO, this is a hack to stop weird issues around the time of a new reading causing issues
      return;
    }
    this.predictions = predictions;
  }

  CleanSGV? getPredictedValue(int numberReadinggsAhead) {
    if (predictions == null) {
      return null;
    }

    // 0 is 1 reading ahead
    var index = numberReadinggsAhead - 1;
    if (index < 0 || index >= predictions!.length) {
      return null;
    }
    var pred = predictions![index];
    if (pred == null) {
      return null;
    }
    // caching is to stop changes in prediction list.
    return pred;
  }

  static List<CleanSGV> _makeChained(List<CleanSGV> sgvs) {
    if (sgvs.isEmpty || sgvs.length == 1) {
      return sgvs;
    }

    List<CleanSGV> chainedSGVs = [sgvs.first];

    var dateBefore = sgvs.first.date;
    for (var i = 1; i < sgvs.length; i++) {
      var sgv = sgvs[i];

      var dinm = dateBefore.difference(sgv.date).inMinutes;

      // We dont want the chain to be too close together and we dont want to chain too far apart
      if (dinm >= MIN_BEFORE_MINS && dinm <= 30) {
        chainedSGVs.last.before = sgv;
        dateBefore = sgv.date;
        chainedSGVs.add(sgv);
      }
    }

    return chainedSGVs;
  }

  static int count() {
    return last2Days.value.length;
  }

  // This is the root signal that caches and filters all SGVs from the last two days
  static ASignal<List<CleanSGV>> last2Days = ASignal([], debugLabel: 'CleanSGVLast2Days');

  static ASignal<List<CleanSGV>> last3Hours = ASignal([], debugLabel: 'CleanSGVlastSGV3Hours');

  static ASignal<CleanSGV?> lastSGV = ASignal(null, debugLabel: 'CleanSGVlastSGV');

  static Future<void> setupSQLSignals() async {
    await signalAssign(last2Days, () async {
      List<SGV> rawSGVs = SGV.last2Days.value;
      return _makeChained(rawSGVs.map((e) => CleanSGV(e.value, e.date)).toList());
    }, debugLabel: "Clean2DaysQuery", dependencies: [SGV.last2Days]);

    await signalAssign(last3Hours, () => last2Days.value.where((e) => e.withinLast3Hours).toList(), debugLabel: 'last3HoursQuery');

    await signalAssign(lastSGV, () {
      var lastSGV = last2Days.value.firstOrNull;
      if (lastSGV == null) {
        return null;
      }

      var predictions = PredictionService().getPredictedReadings(lastSGV);
      lastSGV.setPredictions(predictions);

      return lastSGV;
    }, debugLabel: 'lastSGVQuery');
  }

  // The reason for cleanAgoReadings is that we want a minimal set of readings to get information from
  // There can be multiple close SGV readings that muddy the waters on things like diffs
  // e.g. if two readings are a millisecond apart, but only 1 difference in value, than the rate per 5 mins would be huge
  static List<CleanSGV> cleanAgoReadings(Duration ago) {
    var last = lastSGV.value; // Make sure lastSGV is up to date
    if (last == null) {
      return [];
    }
    // The max readings will be the amount of readings the min distance apart within the duration (+1 for goot measure)
    var maxReadingsAgo = (ago.inMinutes ~/ MIN_BEFORE_MINS) + 1;
    return last.beforeN(maxReadingsAgo).where((e) => e.age <= ago).toList();
  }

  // Trigger windows are tricky
  // If for example you have a 10 minute trigger window then what you really want is the last 3 readings (0mins, 5mins, 10mins),
  // But the window shifts because time keeps going forward, then you might want (4mins, 9mins, 14mins)
  // What you want to happen is normalize to a new reading
  // That is, for 10 minutes you want to look at the last 10 minutes when the latest reading is 0 minutes old.
  // If the latest reading is 1 minute old, you want to look at the last 11 minutes.
  static List<CleanSGV> sgvsInTriggerWindow(int minutesToTrigger) {
    if (minutesToTrigger < 0) {
      return [];
    }
    var lastSGV = CleanSGV.lastSGV.value;

    if (lastSGV == null) {
      return [];
    }

    var age = triggerWindowAge(lastSGV.age, minutesToTrigger);

    var sgvs = cleanAgoReadings(age);
    return sgvs;
  }

  static Duration triggerWindowAge(Duration lastSGVAge, int minutesToTrigger) {
    var minutesDuration = Duration(minutes: minutesToTrigger);
    // We grab the last SGV and all SGVs before that for the minutes to trigger
    // This solves a lot of missing data issues and edge case issues because it removes clock.now() from the number of sgvs to use

    // We max out the last reading at 5 minutes old
    var normalizeToCurrentSGV = Duration(milliseconds: min(lastSGVAge.inMilliseconds, 300000));

    return minutesDuration + normalizeToCurrentSGV + LAG_WIGGLE_DURATION;
  }
}
