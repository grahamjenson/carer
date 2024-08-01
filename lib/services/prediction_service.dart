import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';

class PredictionService {
  static final PredictionService _singleton = PredictionService._();

  factory PredictionService() => _singleton;

  PredictionService._();

  final Computed<List<CleanSGV>> predictionsSignal = acomputed(() {
    var _ = TimerService().minuteSignal.value;
    Exp2Predictor exp2predictor = Exp2Predictor();
    exp2predictor.init();
    if (exp2predictor.regression.runtimeType == NoopRegression) {
      return [];
    }

    return exp2predictor.predictNextHour();
  }, [], debugLabel: "PredictionService");

  List<CleanSGV> get predictions => predictionsSignal.value;

  List<Range5> get predictionRanges {
    return predictions.map((e) {
      var (range, _) = targetRange(e.value);
      return range;
    }).toList();
  }

  CleanSGV? getPredictionAt(DateTime time) {
    return predictions.firstWhereOrNull((e) => e.date.isAfter(time));
  }

  int getPredictionAtValue(DateTime time) {
    var pv = getPredictionAt(time);
    if (pv == null) {
      return 0;
    }
    return pv.value;
  }

  Range5? atPredictedTime(DateTime time) {
    CleanSGV? sgv = predictions.firstWhereOrNull((e) => e.date.isAfter(time));
    if (sgv == null) {
      return null;
    }
    var (range, _) = targetRange(sgv.value);

    return range;
  }
}
