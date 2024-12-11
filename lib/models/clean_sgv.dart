import 'package:carer/models/model.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class CleanSGV extends ASGV with DateMixin {
  @override
  final int value;

  @override
  final DateTime date;

  // The reason for these methods is that we take the most recent CleanSGV and find the previous one
  // Sometimes there can be very close together values and may affect things like the rate of change
  // This way we pick the latextest value and follow the chain back of appropriatly seperated values

  CleanSGV? before; // previous SVGs ID

  List<CleanSGV> lastReadingsAfter(Duration ago) {
    return beforeN((ago.inMinutes ~/ 5) + 1).where((e) => e.age <= ago).toList();
  }

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
      if (dinm > 3 && dinm < 30) {
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
}
