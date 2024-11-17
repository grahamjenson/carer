import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum FlowDataNames {
  agreedTermsAndConditionsTimeStamp,
  agreedPrivacyPolicyTimeStamp,
}

class FlowData {
  static final FlowData _singleton = FlowData._();
  factory FlowData() => _singleton;
  FlowData._();

  final Map<FlowDataNames, ASignal> _signals = {
    FlowDataNames.agreedPrivacyPolicyTimeStamp: ASignal<int>(0, debugLabel: "agreedPrivacyPolicyTimeStamp"),
    FlowDataNames.agreedTermsAndConditionsTimeStamp: ASignal<int>(0, debugLabel: "agreedTermsAndConditionsTimeStamp"),
  };

  // Constructor
  Future<bool> setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    await prefs.internalPopulate();

    agreedPrivacyPolicy = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(FlowDataNames.agreedPrivacyPolicyTimeStamp.name, defaultValue: 0)!,
    );

    agreedTermsAndConditions = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(FlowDataNames.agreedTermsAndConditionsTimeStamp.name, defaultValue: 0)!,
    );

    aeffect(
      () {
        prefs.setInt(FlowDataNames.agreedPrivacyPolicyTimeStamp.name, _signals[FlowDataNames.agreedPrivacyPolicyTimeStamp]!.value);
      },
      debugLabel: "agreedPrivacyPolicyTimeStamp",
    );

    aeffect(
      () {
        prefs.setInt(FlowDataNames.agreedTermsAndConditionsTimeStamp.name, _signals[FlowDataNames.agreedTermsAndConditionsTimeStamp]!.value);
      },
      debugLabel: "agreedTermsAndConditionsTimeStamp",
    );

    return true;
  }

  // Getters
  static DateTime minDateTime = DateTime(2024);

  DateTime? get agreedPrivacyPolicy {
    var timeStamp = _signals[FlowDataNames.agreedPrivacyPolicyTimeStamp]!.value;

    if (timeStamp == 0) {
      return null;
    }
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    if (dateTime.isBefore(minDateTime)) {
      return null;
    }
    return dateTime;
  }

  DateTime? get agreedTermsAndConditions {
    var timeStamp = _signals[FlowDataNames.agreedTermsAndConditionsTimeStamp]!.value;
    if (timeStamp == 0) {
      return null;
    }
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    if (dateTime.isBefore(minDateTime)) {
      return null;
    }
    return dateTime;
  }

  // Setters
  set agreedPrivacyPolicy(DateTime? value) {
    if (value == null) {
      _signals[FlowDataNames.agreedPrivacyPolicyTimeStamp]!.value = 0;
      return;
    }
    _signals[FlowDataNames.agreedPrivacyPolicyTimeStamp]!.value = value.millisecondsSinceEpoch;
  }

  set agreedTermsAndConditions(DateTime? value) {
    if (value == null) {
      _signals[FlowDataNames.agreedTermsAndConditionsTimeStamp]!.value = 0;
      return;
    }
    _signals[FlowDataNames.agreedTermsAndConditionsTimeStamp]!.value = value.millisecondsSinceEpoch;
  }
}
