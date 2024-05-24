import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/t1d_cn.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

abstract class Predictor {
  final SettingsCN settings;
  final T1DCN t1d;

  const Predictor({required this.settings, required this.t1d});
  Future<SGV?> predictBGL(int minutes);
}

// This predicator just takes the last 15 mins of data and extends it out.
class SimplePredictor extends Predictor {
  const SimplePredictor({required super.settings, required super.t1d});

  @override
  Future<SGV?> predictBGL(int minutes) async {
    var lastSGV = await SGV.lastSGV();
    if (lastSGV == null) {
      return null;
    }
    var diffs = await t1d.diffPer5Minute(15);
    if (diffs.isEmpty) {
      return null;
    }

    return SGV(
        value: lastSGV.value + (mean(diffs) * (minutes / 5).round()),
        date: clock.now().add(Duration(minutes: minutes)));
  }
}
