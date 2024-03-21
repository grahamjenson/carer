import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:carer/nsclient/summary.dart';

abstract class Predictor {
  final Settings settings;
  final T1DCN t1d;

  const Predictor({required this.settings, required this.t1d});
  SGV? predictBGL(int minutes);
}

// This predicator just takes the last 15 mins of data and extends it out.
class SimplePredictor extends Predictor {
  const SimplePredictor({required super.settings, required super.t1d});

  @override
  SGV? predictBGL(int minutes) {
    var lastSGV = t1d.summary.lastSGV;
    if (lastSGV == null) {
      return null;
    }
    var diffs = t1d.diffPer5Minute(15);
    if (diffs.isEmpty) {
      return null;
    }
    int mean = (diffs.reduce((a, b) => a + b) / diffs.length).round();
    return SGV(
        sgv: lastSGV.sgv + (mean * (minutes / 5).round()),
        mills: DateTime.now().add(Duration(minutes: minutes)));
  }
}
