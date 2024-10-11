import 'package:carer/models/clean_sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/services/timer_service.dart';
import 'package:collection/collection.dart';

class PredictionService {
  static final PredictionService _singleton = PredictionService._();

  static CleanSGV? _getPredictionAt(List<CleanSGV> predictions, DateTime time) {
    return predictions.firstWhereOrNull((e) => e.date.isAfter(time));
  }

  factory PredictionService() => _singleton;

  PredictionService._();

  // Returns a list of readings every 5 minutes from the last reading
  List<CleanSGV> getPredictedReadings(CleanSGV lastSGV, {int numberOfReadings = 5}) {
    var predictions = getPredictions(lastSGV.before5);

    List<CleanSGV> prs = [];
    for (int i = 0; i <= numberOfReadings; i++) {
      var futureDate = lastSGV.date.add(Duration(minutes: 5 * (i + 1)));
      var presgv = _getPredictionAt(predictions, futureDate);
      if (presgv != null) {
        prs.add(presgv);
      }
    }

    return prs;
  }

  // Returns a list of readings every minute
  List<CleanSGV> getPredictions(List<CleanSGV?> lastSGVs) {
    var _ = TimerService().minuteSignal.value;
    Exp2Predictor exp2predictor = Exp2Predictor();
    exp2predictor.init(lastSGVs: lastSGVs);
    if (exp2predictor.regression.runtimeType == NoopRegression) {
      final List<CleanSGV> em = [];
      return em;
    }
    return exp2predictor.predictNextHour();
  }
}
