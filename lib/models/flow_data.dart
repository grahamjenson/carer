import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';

enum FlowDataNames {
  agreedTermsOfServicePrivacyTimeStamp,
}

class FlowData {
  static final FlowData _singleton = FlowData._();
  factory FlowData() => _singleton;
  FlowData._();

  final Map<FlowDataNames, ASignal> _signals = {
    FlowDataNames.agreedTermsOfServicePrivacyTimeStamp: ASignal<int>(0, debugLabel: "agreedTermsOfServicePrivacyTimeStamp"),
  };

  // Constructor
  Future<bool> setupDBPropagation() async {
    var prefs = await KeyValueStore.instance;
    await prefs.internalPopulate();

    agreedTermsOfServicePrivacy = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(FlowDataNames.agreedTermsOfServicePrivacyTimeStamp.name, defaultValue: 0)!,
    );

    aeffect(
      () {
        prefs.setInt(FlowDataNames.agreedTermsOfServicePrivacyTimeStamp.name, _signals[FlowDataNames.agreedTermsOfServicePrivacyTimeStamp]!.value);
      },
      debugLabel: "writeagreedTermsOfServicePrivacyTimeStamp",
    );

    return true;
  }

  // Getters
  // minDateTime is used to invalidate the agreement if the terms change
  static DateTime minDateTime = DateTime(2024);

  DateTime? get agreedTermsOfServicePrivacy {
    var timeStamp = _signals[FlowDataNames.agreedTermsOfServicePrivacyTimeStamp]!.value;
    if (timeStamp == 0) {
      return null;
    }
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    if (dateTime.isBefore(minDateTime)) {
      return null;
    }
    return dateTime;
  }

  set agreedTermsOfServicePrivacy(DateTime? value) {
    if (value == null) {
      _signals[FlowDataNames.agreedTermsOfServicePrivacyTimeStamp]!.value = 0;
      return;
    }
    _signals[FlowDataNames.agreedTermsOfServicePrivacyTimeStamp]!.value = value.millisecondsSinceEpoch;
  }
}
