import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:collection/collection.dart';

class PredictionService {
  static final PredictionService _singleton = PredictionService._();

  static CleanSGV? _getPredictionAt(List<CleanSGV> predictions, DateTime time) {
    return predictions.firstWhereOrNull((e) => e.date.isAfter(time));
  }

  factory PredictionService() => _singleton;

  late ASignal<List<CleanSGV>> predictionsSignal = ASignal<List<CleanSGV>>([], debugLabel: "Predictions");
  late ASignal<List<CleanSGV>> predictionsForReadingsSignal = ASignal<List<CleanSGV>>([], debugLabel: "predictionsForReadings");

  PredictionService._() {
    signalAssign(predictionsSignal, () {
      var _ = TimerService().minuteSignal.value;
      Exp2Predictor exp2predictor = Exp2Predictor();
      exp2predictor.init();
      if (exp2predictor.regression.runtimeType == NoopRegression) {
        final List<CleanSGV> em = [];
        return em;
      }
      return exp2predictor.predictNextHour();
    }, debugLabel: "Predictions", dependencies: [TimerService().minuteSignal, CleanSGV.lastSGV]);

    signalAssign(predictionsForReadingsSignal, () {
      var lastSGV = CleanSGV.lastSGV.value;
      if (lastSGV == null) {
        final List<CleanSGV> em = [];
        return em;
      }

      List<CleanSGV?> prs = [];
      for (int i = 0; i < 6; i++) {
        var futureDate = lastSGV.date.add(Duration(minutes: 5 * (i + 1)));
        prs.add(_getPredictionAt(predictions, futureDate));
      }

      return prs.whereType<CleanSGV>().toList();
    }, debugLabel: "PredictionService", dependencies: [predictionsSignal]);
  }

  List<CleanSGV> get predictions => predictionsSignal.value;
  List<CleanSGV> get predictionsForReadings => predictionsForReadingsSignal.value;

  // Get Values at specific time
  CleanSGV? getPredictionAt(DateTime time) {
    return _getPredictionAt(predictions, time);
  }

  int getPredictionAtValue(DateTime time) {
    var pv = getPredictionAt(time);
    if (pv == null) {
      return 0;
    }
    return pv.value;
  }

  Range5? getPredictionAtRange(DateTime time) {
    CleanSGV? sgv = predictions.firstWhereOrNull((e) => e.date.isAfter(time));
    if (sgv == null) {
      return null;
    }

    var (range, _) = targetRange(sgv.value);

    return range;
  }

  // Get values ahead of the current reading
  CleanSGV? getReadingsAhead(int readingsAhead) {
    return predictionsForReadings.elementAtOrNull(readingsAhead - 1);
  }

  int getReadingsAheadValue(int readingsAhead) {
    var sgv = getReadingsAhead(readingsAhead);
    if (sgv == null) {
      return 0;
    }
    return sgv.value;
  }

  Range5? getReadingsAheadRange(int readingsAhead) {
    var sgv = getReadingsAhead(readingsAhead);
    if (sgv == null) {
      return null;
    }
    var (range, _) = targetRange(sgv.value);
    return range;
  }
}
