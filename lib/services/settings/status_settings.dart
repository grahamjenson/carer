import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _StatusNames {
  cannulaDays,
  sensorDays,
  infoDisabledSet,
  statusDisabledSet,
}

class StatusSettings {
  static final StatusSettings _singleton = StatusSettings._();
  factory StatusSettings() => _singleton;

  final Map<_StatusNames, ASignal> _signals = {
    _StatusNames.cannulaDays: ASignal<int>(3, debugLabel: 'cannulaDays'),
    _StatusNames.sensorDays: ASignal<int>(10, debugLabel: 'sensorDays'),
    _StatusNames.infoDisabledSet: ASignal<Set<String>>({}, debugLabel: 'infoDisabled'),
    _StatusNames.statusDisabledSet: ASignal<Set<String>>({}, debugLabel: 'statusDisabled'),
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

  bool infoDisabledContains(String name) => _signals[_StatusNames.infoDisabledSet]!.value.contains(name);
  void infoDisabledAdd(String name) {
    var set = Set<String>.from(_signals[_StatusNames.infoDisabledSet]!.value);
    set.add(name);
    _signals[_StatusNames.infoDisabledSet]!.value = set;
  }

  void infoDisabledRemove(String name) {
    var set = Set<String>.from(_signals[_StatusNames.infoDisabledSet]!.value);
    set.remove(name);
    _signals[_StatusNames.infoDisabledSet]!.value = set;
  }

  bool statusDisabledContains(String name) => _signals[_StatusNames.statusDisabledSet]!.value.contains(name);
  void statusDisabledAdd(String name) {
    var set = Set<String>.from(_signals[_StatusNames.statusDisabledSet]!.value);
    set.add(name);
    _signals[_StatusNames.statusDisabledSet]!.value = set;
  }

  void statusDisabledRemove(String name) {
    var set = Set<String>.from(_signals[_StatusNames.statusDisabledSet]!.value);
    set.remove(name);
    _signals[_StatusNames.statusDisabledSet]!.value = set;
  }

  setupDBPropagation(KeyValueStore prefs) {
    // Assign the values from the DB
    cannulaDays = prefs.getInt(_StatusNames.cannulaDays.name, defaultValue: 3)!;

    sensorDays = prefs.getInt(_StatusNames.sensorDays.name, defaultValue: 10)!;

    _signals[_StatusNames.infoDisabledSet]!.value = prefs.getString(_StatusNames.infoDisabledSet.name, defaultValue: "")!.split(',').toSet();

    _signals[_StatusNames.statusDisabledSet]!.value = prefs.getString(_StatusNames.statusDisabledSet.name, defaultValue: "")!.split(',').toSet();

    aeffect(() => prefs.setInt(_StatusNames.cannulaDays.name, cannulaDays), debugLabel: 'writecannulaDays');

    aeffect(() => prefs.setInt(_StatusNames.sensorDays.name, sensorDays), debugLabel: 'writesensorDays');

    aeffect(() => prefs.setString(_StatusNames.infoDisabledSet.name, _signals[_StatusNames.infoDisabledSet]!.value.join(',')),
        debugLabel: 'writeinfoDisabled');

    aeffect(() => prefs.setString(_StatusNames.statusDisabledSet.name, _signals[_StatusNames.statusDisabledSet]!.value.join(',')),
        debugLabel: 'writestatusDisabled');
  }
}
