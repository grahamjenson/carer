import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum _CSNames {
  carbs1Value,
  carbs2Value,
  carbs3Value,
  carbs4Value,
  tempTargetHypoBottom,
  tempTargetHypoTop,
  tempTargetHypoDuration,
  tempTargetEatingBottom,
  tempTargetEatingTop,
  tempTargetEatingDuration,
  tempTargetActivityBottom,
  tempTargetActivityTop,
  tempTargetActivityDuration,
  ;
}

class CareSettings {
  static final CareSettings _singleton = CareSettings._();
  factory CareSettings() => _singleton;

  final Map<_CSNames, ASignal> _signals = {
    _CSNames.carbs1Value: ASignal<int>(1, debugLabel: "carbs1Value"),
    _CSNames.carbs2Value: ASignal<int>(5, debugLabel: "carbs2Value"),
    _CSNames.carbs3Value: ASignal<int>(10, debugLabel: "carbs3Value"),
    _CSNames.carbs4Value: ASignal<int>(15, debugLabel: "carbs4Value"),
    //
    // HYPO TT
    _CSNames.tempTargetHypoBottom: ASignal<double>(144, debugLabel: "tempTargetHypoBottom"),
    _CSNames.tempTargetHypoTop: ASignal<double>(144, debugLabel: "tempTargetHypoTop"),
    _CSNames.tempTargetHypoDuration: ASignal<int>(30, debugLabel: "tempTargetHypoDuration"),
    //
    // ACTIVITY TT
    _CSNames.tempTargetActivityBottom: ASignal<double>(126.0, debugLabel: "tempTargetActivityBottom"),
    _CSNames.tempTargetActivityTop: ASignal<double>(144.0, debugLabel: "tempTargetActivityTop"),
    _CSNames.tempTargetActivityDuration: ASignal<int>(30, debugLabel: "tempTargetActivityDuration"),
    //
    // EATING TT
    _CSNames.tempTargetEatingBottom: ASignal<double>(90.0, debugLabel: "tempTargetEatingBottom"),
    _CSNames.tempTargetEatingTop: ASignal<double>(90.0, debugLabel: "tempTargetEatingTop"),
    _CSNames.tempTargetEatingDuration: ASignal<int>(30, debugLabel: "tempTargetEatingDuration"),
  };

  CareSettings._();

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  int MIN_CARBS = 1;
  int MAX_CARBS = 50;
  int get carbs1Value => _signals[_CSNames.carbs1Value]!.value;
  set carbs1Value(int value) {
    if (value < MIN_CARBS) {
      value = MIN_CARBS;
    }
    if (value > MAX_CARBS) {
      value = MAX_CARBS;
    }
    _signals[_CSNames.carbs1Value]!.value = value;
  }

  int get carbs2Value => _signals[_CSNames.carbs2Value]!.value;
  set carbs2Value(int value) {
    if (value < MIN_CARBS) {
      value = MIN_CARBS;
    }
    if (value > MAX_CARBS) {
      value = MAX_CARBS;
    }
    _signals[_CSNames.carbs2Value]!.value = value;
  }

  int get carbs3Value => _signals[_CSNames.carbs3Value]!.value;
  set carbs3Value(int value) {
    if (value < MIN_CARBS) {
      value = MIN_CARBS;
    }
    if (value > MAX_CARBS) {
      value = MAX_CARBS;
    }
    _signals[_CSNames.carbs3Value]!.value = value;
  }

  int get carbs4Value => _signals[_CSNames.carbs4Value]!.value;
  set carbs4Value(int value) {
    if (value < MIN_CARBS) {
      value = MIN_CARBS;
    }
    if (value > MAX_CARBS) {
      value = MAX_CARBS;
    }
    _signals[_CSNames.carbs4Value]!.value = value;
  }

  double get tempTargetHypoBottom => _signals[_CSNames.tempTargetHypoBottom]!.value;
  set tempTargetHypoBottom(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetHypoBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetHypoTop]! as ASignal<double>,
      value,
      _signals[_CSNames.tempTargetHypoTop]!.peek(),
    );
  }

  double get tempTargetHypoTop => _signals[_CSNames.tempTargetHypoTop]!.value;
  set tempTargetHypoTop(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetHypoBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetHypoTop]! as ASignal<double>,
      _signals[_CSNames.tempTargetHypoBottom]!.peek(),
      value,
    );
  }

  int get tempTargetHypoDuration => _signals[_CSNames.tempTargetHypoDuration]!.value;
  set tempTargetHypoDuration(int value) {
    _signals[_CSNames.tempTargetHypoDuration]!.value = value;
  }

  double get tempTargetActivityBottom => _signals[_CSNames.tempTargetActivityBottom]!.value;
  set tempTargetActivityBottom(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetActivityBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetActivityTop]! as ASignal<double>,
      value,
      _signals[_CSNames.tempTargetActivityTop]!.peek(),
    );
  }

  double get tempTargetActivityTop => _signals[_CSNames.tempTargetActivityTop]!.value;
  set tempTargetActivityTop(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetActivityBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetActivityTop]! as ASignal<double>,
      _signals[_CSNames.tempTargetActivityBottom]!.peek(),
      value,
    );
  }

  int get tempTargetActivityDuration => _signals[_CSNames.tempTargetActivityDuration]!.value;
  set tempTargetActivityDuration(int value) {
    _signals[_CSNames.tempTargetActivityDuration]!.value = value;
  }

  double get tempTargetEatingBottom => _signals[_CSNames.tempTargetEatingBottom]!.value;
  set tempTargetEatingBottom(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetEatingBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetEatingTop]! as ASignal<double>,
      value,
      _signals[_CSNames.tempTargetEatingTop]!.peek(),
    );
  }

  double get tempTargetEatingTop => _signals[_CSNames.tempTargetEatingTop]!.value;
  set tempTargetEatingTop(double value) {
    rangeSet(
      _signals[_CSNames.tempTargetEatingBottom]! as ASignal<double>,
      _signals[_CSNames.tempTargetEatingTop]! as ASignal<double>,
      _signals[_CSNames.tempTargetEatingBottom]!.peek(),
      value,
    );
  }

  int get tempTargetEatingDuration => _signals[_CSNames.tempTargetEatingDuration]!.value;
  set tempTargetEatingDuration(int value) {
    _signals[_CSNames.tempTargetEatingDuration]!.value = value;
  }

  rangeSet(ASignal<double> bot, ASignal<double> top, double botValue, double topValue) {
    if (botValue < 72) {
      botValue = 72;
    }
    if (botValue > 180) {
      botValue = 180;
    }
    if (topValue < 72) {
      topValue = 72;
    }
    if (topValue > 180) {
      topValue = 180;
    }

    if (botValue > topValue) {
      botValue = topValue;
    }

    bot.value = botValue;
    top.value = topValue;
  }

  setupDBPropagation(KeyValueStore prefs) {
    carbs1Value = prefs.getInt(_CSNames.carbs1Value.name) ?? 1;
    carbs2Value = prefs.getInt(_CSNames.carbs2Value.name) ?? 5;
    carbs3Value = prefs.getInt(_CSNames.carbs3Value.name) ?? 10;
    carbs4Value = prefs.getInt(_CSNames.carbs4Value.name) ?? 15;

    tempTargetHypoBottom = prefs.getDouble(_CSNames.tempTargetHypoBottom.name) ?? 144;
    tempTargetHypoTop = prefs.getDouble(_CSNames.tempTargetHypoTop.name) ?? 144;
    tempTargetHypoDuration = prefs.getInt(_CSNames.tempTargetHypoDuration.name) ?? 30;

    tempTargetActivityBottom = prefs.getDouble(_CSNames.tempTargetActivityBottom.name) ?? 126.0;
    tempTargetActivityTop = prefs.getDouble(_CSNames.tempTargetActivityTop.name) ?? 144.0;
    tempTargetActivityDuration = prefs.getInt(_CSNames.tempTargetActivityDuration.name) ?? 30;

    tempTargetEatingBottom = prefs.getDouble(_CSNames.tempTargetEatingBottom.name) ?? 90.0;
    tempTargetEatingTop = prefs.getDouble(_CSNames.tempTargetEatingTop.name) ?? 90.0;
    tempTargetEatingDuration = prefs.getInt(_CSNames.tempTargetEatingDuration.name) ?? 30;

    aeffect(() => prefs.setInt(_CSNames.carbs1Value.name, carbs1Value), debugLabel: 'writecarbs1Value');
    aeffect(() => prefs.setInt(_CSNames.carbs2Value.name, carbs2Value), debugLabel: 'writecarbs2Value');
    aeffect(() => prefs.setInt(_CSNames.carbs3Value.name, carbs3Value), debugLabel: 'writecarbs3Value');
    aeffect(() => prefs.setInt(_CSNames.carbs4Value.name, carbs4Value), debugLabel: 'writecarbs4Value');

    aeffect(() => prefs.setDouble(_CSNames.tempTargetHypoBottom.name, tempTargetHypoBottom), debugLabel: 'writetempTargetHypoBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetHypoTop.name, tempTargetHypoTop), debugLabel: 'writetempTargetHypoTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetHypoDuration.name, tempTargetHypoDuration), debugLabel: 'writetempTargetHypoDuration');

    aeffect(() => prefs.setDouble(_CSNames.tempTargetActivityBottom.name, tempTargetActivityBottom), debugLabel: 'writetempTargetActivityBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetActivityTop.name, tempTargetActivityTop), debugLabel: 'writetempTargetActivityTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetActivityDuration.name, tempTargetActivityDuration), debugLabel: 'writetempTargetActivityDuration');

    aeffect(() => prefs.setDouble(_CSNames.tempTargetEatingBottom.name, tempTargetEatingBottom), debugLabel: 'writetempTargetEatingBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetEatingTop.name, tempTargetEatingTop), debugLabel: 'writetempTargetEatingTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetEatingDuration.name, tempTargetEatingDuration), debugLabel: 'writetempTargetEatingDuration');
  }
}
