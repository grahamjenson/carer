import 'package:carer/models/sgv.dart';
import 'package:carer/predictors/regressions.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/utils/math.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';

class PredictionService {
  static final PredictionService _singleton = PredictionService._();

  factory PredictionService() => _singleton;

  PredictionService._() {
    effect(() {
      try {
        _updatePrediction();
      } catch (e) {
        print("Error in _updatePrediction PredictionService effect: $e");
      }
    }, debugLabel: "PredictionService");
  }

  final Signal<List<SGV>> _predictionsSignal = Signal([]);
  List<SGV> get predictions => _predictionsSignal.value;

  List<Range5> get predictionRanges {
    return predictions.map((e) {
      var (range, _) = targetRange(e.value);
      return range;
    }).toList();
  }

  Range5 atPredictedTime(int mins) {
    var sgv = predictions.firstWhereOrNull((e) => e.minsAgo >= mins);
    if (sgv == null) {
      return Range5.mid;
    }
    var (range, _) = targetRange(sgv.value);
    return range;
  }

  _updatePrediction() {
    Exp2Predictor exp2predictor = Exp2Predictor();
    exp2predictor.init();
    if (exp2predictor.regression.runtimeType == NoopRegression) {
      print("Regression noop");
      return Range5.mid;
    }

    _predictionsSignal.value = exp2predictor.predictNextHour();
  }
}
