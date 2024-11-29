import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum FlowDataNames {
  agreedTermsOfServiceTimeStamp,
  agreedPrivacyPolicyTimeStamp,
}

class FlowData {
  static final FlowData _singleton = FlowData._();
  factory FlowData() => _singleton;
  FlowData._();

  final Map<FlowDataNames, ASignal> _signals = {
    FlowDataNames.agreedPrivacyPolicyTimeStamp: ASignal<int>(0, debugLabel: "agreedPrivacyPolicyTimeStamp"),
    FlowDataNames.agreedTermsOfServiceTimeStamp: ASignal<int>(0, debugLabel: "agreedTermsOfServiceTimeStamp"),
  };

  // Constructor
  Future<bool> setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    await prefs.internalPopulate();

    agreedPrivacyPolicy = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(FlowDataNames.agreedPrivacyPolicyTimeStamp.name, defaultValue: 0)!,
    );

    agreedTermsOfService = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(FlowDataNames.agreedTermsOfServiceTimeStamp.name, defaultValue: 0)!,
    );

    aeffect(
      () {
        prefs.setInt(FlowDataNames.agreedPrivacyPolicyTimeStamp.name, _signals[FlowDataNames.agreedPrivacyPolicyTimeStamp]!.value);
      },
      debugLabel: "writeAgreedPrivacyPolicyTimeStamp",
    );

    aeffect(
      () {
        prefs.setInt(FlowDataNames.agreedTermsOfServiceTimeStamp.name, _signals[FlowDataNames.agreedTermsOfServiceTimeStamp]!.value);
      },
      debugLabel: "writeAgreedTermsOfServiceTimeStamp",
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

  DateTime? get agreedTermsOfService {
    var timeStamp = _signals[FlowDataNames.agreedTermsOfServiceTimeStamp]!.value;
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

  set agreedTermsOfService(DateTime? value) {
    if (value == null) {
      _signals[FlowDataNames.agreedTermsOfServiceTimeStamp]!.value = 0;
      return;
    }
    _signals[FlowDataNames.agreedTermsOfServiceTimeStamp]!.value = value.millisecondsSinceEpoch;
  }
}
