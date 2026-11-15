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

  profile1Name,
  profile1Duration,
  profile1Percent,
  profile2Name,
  profile2Duration,
  profile2Percent,
  profile3Name,
  profile3Duration,
  profile3Percent,
  profile4Name,
  profile4Duration,
  profile4Percent,
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

    // Profiles
    _CSNames.profile1Name: ASignal<String>("", debugLabel: "profile1Name"),
    _CSNames.profile1Duration: ASignal<int>(0, debugLabel: "profile1Duration"),
    _CSNames.profile1Percent: ASignal<int>(100, debugLabel: "profile1Percent"),

    _CSNames.profile2Name: ASignal<String>("", debugLabel: "profile2Name"),
    _CSNames.profile2Duration: ASignal<int>(0, debugLabel: "profile2Duration"),
    _CSNames.profile2Percent: ASignal<int>(100, debugLabel: "profile2Percent"),

    _CSNames.profile3Name: ASignal<String>("", debugLabel: "profile3Name"),
    _CSNames.profile3Duration: ASignal<int>(0, debugLabel: "profile3Duration"),
    _CSNames.profile3Percent: ASignal<int>(100, debugLabel: "profile3Percent"),

    _CSNames.profile4Name: ASignal<String>("", debugLabel: "profile4Name"),
    _CSNames.profile4Duration: ASignal<int>(0, debugLabel: "profile4Duration"),
    _CSNames.profile4Percent: ASignal<int>(100, debugLabel: "profile4Percent"),
  };

  CareSettings._();

  List<ASignal> allSignals() {
    return _signals.values.toList();
  }

  ASignal<int> get carbs1Signal => _signals[_CSNames.carbs1Value] as ASignal<int>;
  ASignal<int> get carbs2Signal => _signals[_CSNames.carbs2Value] as ASignal<int>;
  ASignal<int> get carbs3Signal => _signals[_CSNames.carbs3Value] as ASignal<int>;
  ASignal<int> get carbs4Signal => _signals[_CSNames.carbs4Value] as ASignal<int>;

  ASignal<double> get tempTargetHypoBottomSignal => _signals[_CSNames.tempTargetHypoBottom] as ASignal<double>;
  ASignal<double> get tempTargetHypoTopSignal => _signals[_CSNames.tempTargetHypoTop] as ASignal<double>;
  ASignal<int> get tempTargetHypoDurationSignal => _signals[_CSNames.tempTargetHypoDuration] as ASignal<int>;

  ASignal<double> get tempTargetActivityBottomSignal => _signals[_CSNames.tempTargetActivityBottom] as ASignal<double>;
  ASignal<double> get tempTargetActivityTopSignal => _signals[_CSNames.tempTargetActivityTop] as ASignal<double>;
  ASignal<int> get tempTargetActivityDurationSignal => _signals[_CSNames.tempTargetActivityDuration] as ASignal<int>;

  ASignal<double> get tempTargetEatingBottomSignal => _signals[_CSNames.tempTargetEatingBottom] as ASignal<double>;
  ASignal<double> get tempTargetEatingTopSignal => _signals[_CSNames.tempTargetEatingTop] as ASignal<double>;
  ASignal<int> get tempTargetEatingDurationSignal => _signals[_CSNames.tempTargetEatingDuration] as ASignal<int>;

  ASignal<String> get profile1NameSignal => _signals[_CSNames.profile1Name] as ASignal<String>;
  ASignal<int> get profile1DurationSignal => _signals[_CSNames.profile1Duration] as ASignal<int>;
  ASignal<int> get profile1PercentSignal => _signals[_CSNames.profile1Percent] as ASignal<int>;

  ASignal<String> get profile2NameSignal => _signals[_CSNames.profile2Name] as ASignal<String>;
  ASignal<int> get profile2DurationSignal => _signals[_CSNames.profile2Duration] as ASignal<int>;
  ASignal<int> get profile2PercentSignal => _signals[_CSNames.profile2Percent] as ASignal<int>;

  ASignal<String> get profile3NameSignal => _signals[_CSNames.profile3Name] as ASignal<String>;
  ASignal<int> get profile3DurationSignal => _signals[_CSNames.profile3Duration] as ASignal<int>;
  ASignal<int> get profile3PercentSignal => _signals[_CSNames.profile3Percent] as ASignal<int>;

  ASignal<String> get profile4NameSignal => _signals[_CSNames.profile4Name] as ASignal<String>;
  ASignal<int> get profile4DurationSignal => _signals[_CSNames.profile4Duration] as ASignal<int>;
  ASignal<int> get profile4PercentSignal => _signals[_CSNames.profile4Percent] as ASignal<int>;

  ////
  // GETTERS & SETTERS
  ////

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
    // Carbs
    carbs1Signal.value = prefs.getInt(_CSNames.carbs1Value.name) ?? 1;
    carbs2Signal.value = prefs.getInt(_CSNames.carbs2Value.name) ?? 5;
    carbs3Signal.value = prefs.getInt(_CSNames.carbs3Value.name) ?? 10;
    carbs4Signal.value = prefs.getInt(_CSNames.carbs4Value.name) ?? 15;

    aeffect(() => prefs.setInt(_CSNames.carbs1Value.name, carbs1Signal.value), debugLabel: 'writecarbs1Value');
    aeffect(() => prefs.setInt(_CSNames.carbs2Value.name, carbs2Signal.value), debugLabel: 'writecarbs2Value');
    aeffect(() => prefs.setInt(_CSNames.carbs3Value.name, carbs3Signal.value), debugLabel: 'writecarbs3Value');
    aeffect(() => prefs.setInt(_CSNames.carbs4Value.name, carbs4Signal.value), debugLabel: 'writecarbs4Value');

    // Temp Targets
    tempTargetHypoBottom = prefs.getDouble(_CSNames.tempTargetHypoBottom.name) ?? 144;
    tempTargetHypoTop = prefs.getDouble(_CSNames.tempTargetHypoTop.name) ?? 144;
    tempTargetHypoDuration = prefs.getInt(_CSNames.tempTargetHypoDuration.name) ?? 30;

    tempTargetActivityBottom = prefs.getDouble(_CSNames.tempTargetActivityBottom.name) ?? 126.0;
    tempTargetActivityTop = prefs.getDouble(_CSNames.tempTargetActivityTop.name) ?? 144.0;
    tempTargetActivityDuration = prefs.getInt(_CSNames.tempTargetActivityDuration.name) ?? 30;

    tempTargetEatingBottom = prefs.getDouble(_CSNames.tempTargetEatingBottom.name) ?? 90.0;
    tempTargetEatingTop = prefs.getDouble(_CSNames.tempTargetEatingTop.name) ?? 90.0;
    tempTargetEatingDuration = prefs.getInt(_CSNames.tempTargetEatingDuration.name) ?? 30;

    aeffect(() => prefs.setDouble(_CSNames.tempTargetHypoBottom.name, tempTargetHypoBottom), debugLabel: 'writeTempTargetHypoBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetHypoTop.name, tempTargetHypoTop), debugLabel: 'writeTempTargetHypoTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetHypoDuration.name, tempTargetHypoDuration), debugLabel: 'writeTempTargetHypoDuration');

    aeffect(() => prefs.setDouble(_CSNames.tempTargetActivityBottom.name, tempTargetActivityBottom), debugLabel: 'writeTempTargetActivityBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetActivityTop.name, tempTargetActivityTop), debugLabel: 'writeTempTargetActivityTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetActivityDuration.name, tempTargetActivityDuration), debugLabel: 'writeTempTargetActivityDuration');

    aeffect(() => prefs.setDouble(_CSNames.tempTargetEatingBottom.name, tempTargetEatingBottom), debugLabel: 'writeTempTargetEatingBottom');
    aeffect(() => prefs.setDouble(_CSNames.tempTargetEatingTop.name, tempTargetEatingTop), debugLabel: 'writeTempTargetEatingTop');
    aeffect(() => prefs.setInt(_CSNames.tempTargetEatingDuration.name, tempTargetEatingDuration), debugLabel: 'writeTempTargetEatingDuration');

    // Profiles
    profile1NameSignal.value = prefs.getString(_CSNames.profile1Name.name) ?? "";
    profile1DurationSignal.value = prefs.getInt(_CSNames.profile1Duration.name) ?? 0;
    profile1PercentSignal.value = prefs.getInt(_CSNames.profile1Percent.name) ?? 100;

    profile2NameSignal.value = prefs.getString(_CSNames.profile2Name.name) ?? "";
    profile2DurationSignal.value = prefs.getInt(_CSNames.profile2Duration.name) ?? 0;
    profile2PercentSignal.value = prefs.getInt(_CSNames.profile2Percent.name) ?? 100;

    profile3NameSignal.value = prefs.getString(_CSNames.profile3Name.name) ?? "";
    profile3DurationSignal.value = prefs.getInt(_CSNames.profile3Duration.name) ?? 0;
    profile3PercentSignal.value = prefs.getInt(_CSNames.profile3Percent.name) ?? 100;

    profile4NameSignal.value = prefs.getString(_CSNames.profile4Name.name) ?? "";
    profile4DurationSignal.value = prefs.getInt(_CSNames.profile4Duration.name) ?? 0;
    profile4PercentSignal.value = prefs.getInt(_CSNames.profile4Percent.name) ?? 100;

    aeffect(() => prefs.setString(_CSNames.profile1Name.name, profile1NameSignal.value), debugLabel: 'writeProfile1Name');
    aeffect(() => prefs.setInt(_CSNames.profile1Duration.name, profile1DurationSignal.value), debugLabel: 'writeProfile1Duration');
    aeffect(() => prefs.setInt(_CSNames.profile1Percent.name, profile1PercentSignal.value), debugLabel: 'writeProfile1Percent');

    aeffect(() => prefs.setString(_CSNames.profile2Name.name, profile2NameSignal.value), debugLabel: 'writeProfile2Name');
    aeffect(() => prefs.setInt(_CSNames.profile2Duration.name, profile2DurationSignal.value), debugLabel: 'writeProfile2Duration');
    aeffect(() => prefs.setInt(_CSNames.profile2Percent.name, profile2PercentSignal.value), debugLabel: 'writeProfile2Percent');

    aeffect(() => prefs.setString(_CSNames.profile3Name.name, profile3NameSignal.value), debugLabel: 'writeProfile3Name');
    aeffect(() => prefs.setInt(_CSNames.profile3Duration.name, profile3DurationSignal.value), debugLabel: 'writeProfile3Duration');
    aeffect(() => prefs.setInt(_CSNames.profile3Percent.name, profile3PercentSignal.value), debugLabel: 'writeProfile3Percent');

    aeffect(() => prefs.setString(_CSNames.profile4Name.name, profile4NameSignal.value), debugLabel: 'writeProfile4Name');
    aeffect(() => prefs.setInt(_CSNames.profile4Duration.name, profile4DurationSignal.value), debugLabel: 'writeProfile4Duration');
    aeffect(() => prefs.setInt(_CSNames.profile4Percent.name, profile4PercentSignal.value), debugLabel: 'writeProfile4Percent');
  }
}
