import 'package:carer/models/details/info/info_service.dart';
import 'package:carer/models/details/status/status_service.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _StatusNames {
  cannulaDays,
  sensorDays,
  infoEnabledSet,
  statusEnabledSet,
}

final Set<String> defaultInfoSet = Info.values.map((e) => e.name).toSet();
final Set<String> defaultStatusSet = Status.values.map((e) => e.name).toSet();

final String defaultStatusString = Status.values.map((e) => e.name).join(',');
final String defaultInfoString = Info.values.map((e) => e.name).join(',');

class StatusSettings {
  static final StatusSettings _singleton = StatusSettings._();
  factory StatusSettings() => _singleton;

  final Map<_StatusNames, ASignal> _signals = {
    _StatusNames.cannulaDays: ASignal<int>(3, debugLabel: 'cannulaDays'),
    _StatusNames.sensorDays: ASignal<int>(10, debugLabel: 'sensorDays'),
    _StatusNames.infoEnabledSet:
        ASignal<Set<String>>(defaultInfoSet, debugLabel: 'infoEnabled'), // Comma Seperated List of INFO types that are enabled
    _StatusNames.statusEnabledSet:
        ASignal<Set<String>>(defaultStatusSet, debugLabel: 'statusEnabled'), // Comma Seperated List of INFO types that are enabled
  };

  StatusSettings._();

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

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

  bool infoEnabledContains(String name) => _signals[_StatusNames.infoEnabledSet]!.value.contains(name);
  void infoEnabledAdd(String name) {
    var set = Set<String>.from(_signals[_StatusNames.infoEnabledSet]!.value);
    set.add(name);
    _signals[_StatusNames.infoEnabledSet]!.value = set;
  }

  void infoEnabledRemove(String name) {
    var set = Set<String>.from(_signals[_StatusNames.infoEnabledSet]!.value);
    set.remove(name);
    _signals[_StatusNames.infoEnabledSet]!.value = set;
  }

  bool statusEnabledContains(String name) => _signals[_StatusNames.statusEnabledSet]!.value.contains(name);
  void statusEnabledAdd(String name) {
    var set = Set<String>.from(_signals[_StatusNames.statusEnabledSet]!.value);
    set.add(name);
    _signals[_StatusNames.statusEnabledSet]!.value = set;
  }

  void statusEnabledRemove(String name) {
    var set = Set<String>.from(_signals[_StatusNames.statusEnabledSet]!.value);
    set.remove(name);
    _signals[_StatusNames.statusEnabledSet]!.value = set;
  }

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    cannulaDays = prefs.getInt(_StatusNames.cannulaDays.name, defaultValue: 3)!;

    sensorDays = prefs.getInt(_StatusNames.sensorDays.name, defaultValue: 10)!;

    _signals[_StatusNames.infoEnabledSet]!.value =
        prefs.getString(_StatusNames.infoEnabledSet.name, defaultValue: defaultInfoString)!.split(',').toSet();

    _signals[_StatusNames.statusEnabledSet]!.value =
        prefs.getString(_StatusNames.statusEnabledSet.name, defaultValue: defaultStatusString)!.split(',').toSet();

    aeffect(() => prefs.setInt(_StatusNames.cannulaDays.name, cannulaDays), debugLabel: 'writecannulaDays');

    aeffect(() => prefs.setInt(_StatusNames.sensorDays.name, sensorDays), debugLabel: 'writesensorDays');

    aeffect(() => prefs.setString(_StatusNames.infoEnabledSet.name, _signals[_StatusNames.infoEnabledSet]!.value.join(',')),
        debugLabel: 'writeinfoEnabled');

    aeffect(() => prefs.setString(_StatusNames.statusEnabledSet.name, _signals[_StatusNames.statusEnabledSet]!.value.join(',')),
        debugLabel: 'writestatusEnabled');
  }
}
