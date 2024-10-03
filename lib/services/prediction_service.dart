import 'package:carer/models/clean_sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:collection/collection.dart';

class PredictionService {
  static final PredictionService _singleton = PredictionService._();

  static CleanSGV? _getPredictionAt(List<CleanSGV> predictions, DateTime time) {
    return predictions.firstWhereOrNull((e) => e.date.isAfter(time));
  }

  factory PredictionService() => _singleton;

  PredictionService._() {
    // Attach the predictions to the lastest SGV
    aeffect(() {
      var lastSGV = CleanSGV.lastSGV.value;
      if (lastSGV == null) {
        return;
      }
      if (lastSGV.predictions != null && lastSGV.predictions!.isNotEmpty) {
        return;
      }

      var predictions = _getPredictions();

      List<CleanSGV?> prs = [];
      for (int i = 0; i < 6; i++) {
        var futureDate = lastSGV.date.add(Duration(minutes: 5 * (i + 1)));
        prs.add(_getPredictionAt(predictions, futureDate));
      }

      lastSGV.setPredictions(prs);
    }, debugLabel: "PredictionService", dependencies: [CleanSGV.lastSGV]);
  }

  List<CleanSGV> _getPredictions() {
    var _ = TimerService().minuteSignal.value;
    Exp2Predictor exp2predictor = Exp2Predictor();
    exp2predictor.init();
    if (exp2predictor.regression.runtimeType == NoopRegression) {
      final List<CleanSGV> em = [];
      return em;
    }
    return exp2predictor.predictNextHour();
  }
}
