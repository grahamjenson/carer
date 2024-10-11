import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _StatusNames {
  cannulaDays,
  sensorDays,
}

class StatusSettings {
  static final StatusSettings _singleton = StatusSettings._();
  factory StatusSettings() => _singleton;

  final Map<_StatusNames, ASignal> _signals = {
    _StatusNames.cannulaDays: ASignal<int>(3, debugLabel: 'cannulaDays'),
    _StatusNames.sensorDays: ASignal<int>(10, debugLabel: 'sensorDays'),
  };

  StatusSettings._();

  int get cannulaDays => _signals[_StatusNames.cannulaDays]!.value;
  set cannulaDays(int value) {
    if (value < 1 || value > 8) {
      return;
    }
    _signals[_StatusNames.cannulaDays]!.value = value;
  }

  Duration get cannulaDuration => Duration(days: cannulaDays);

  int get sensorDays => _signals[_StatusNames.sensorDays]!.value;
  set sensorDays(int value) {
    if (value < 3 || value > 14) {
      return;
    }
    _signals[_StatusNames.sensorDays]!.value = value;
  }

  Duration get sensorDuration => Duration(days: sensorDays);

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    cannulaDays = prefs.getInt(_StatusNames.cannulaDays.name, defaultValue: 3)!;

    sensorDays = prefs.getInt(_StatusNames.sensorDays.name, defaultValue: 10)!;

    aeffect(() => prefs.setInt(_StatusNames.cannulaDays.name, cannulaDays), debugLabel: 'cannulaDays');

    aeffect(() => prefs.setInt(_StatusNames.sensorDays.name, sensorDays), debugLabel: 'sensorDays');
  }
}
