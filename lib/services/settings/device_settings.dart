import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _DeviceNames {
  cannulaDays,
  sensorDays,
}

class DeviceSettings {
  static final DeviceSettings _singleton = DeviceSettings._();
  factory DeviceSettings() => _singleton;

  final Map<_DeviceNames, ASignal> _signals = {
    _DeviceNames.cannulaDays: ASignal<int>(3, debugLabel: 'cannulaDays'),
    _DeviceNames.sensorDays: ASignal<int>(10, debugLabel: 'sensorDays'),
  };

  DeviceSettings._();

  int get cannulaDays => _signals[_DeviceNames.cannulaDays]!.value;
  set cannulaDays(int value) {
    if (value < 1 || value > 8) {
      return;
    }
    _signals[_DeviceNames.cannulaDays]!.value = value;
  }

  Duration get cannulaDuration => Duration(days: cannulaDays);

  int get sensorDays => _signals[_DeviceNames.sensorDays]!.value;
  set sensorDays(int value) {
    if (value < 3 || value > 14) {
      return;
    }
    _signals[_DeviceNames.sensorDays]!.value = value;
  }

  Duration get sensorDuration => Duration(days: sensorDays);

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    cannulaDays = prefs.getInt(_DeviceNames.cannulaDays.name, defaultValue: 3)!;

    sensorDays = prefs.getInt(_DeviceNames.sensorDays.name, defaultValue: 10)!;

    aeffect(() => prefs.setInt(_DeviceNames.cannulaDays.name, cannulaDays));

    aeffect(() => prefs.setInt(_DeviceNames.sensorDays.name, sensorDays));
  }
}
