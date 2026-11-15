import 'dart:convert';

import 'package:carer/utils/logs.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/services.dart';

JsonDecoder decoder = const JsonDecoder();
JsonEncoder encoder = const JsonEncoder.withIndent('  ');

(dynamic, Object?) tryDecodeJson(String input) {
  try {
    return (decoder.convert(input), null);
  } catch (e) {
    return (null, e);
  }
}

String prettyPrintDecodedJson(Map<String, dynamic> input) {
  try {
    var prettyString = encoder.convert(input);
    var str = "";
    prettyString.split('\n').forEach((element) => str += "$element\n");
    return str;
  } catch (e, stackTrace) {
    Errors.captureError(e, stackTrace, name: "prettyPrintDecodedJson");
    return input.toString();
  }
}

String truncateString(String str, int maxLength) {
  if (str.length <= maxLength) {
    return str;
  } else {
    return '${str.substring(0, maxLength)}...';
  }
}

String toMax2dpStr(num value) {
  var x = toMax2dp(value);
  if (x == x.toInt()) {
    return x.toInt().toString();
  }
  return x.toString();
}

class StringAssets {
  static final StringAssets _singleton = StringAssets._();
  factory StringAssets() => _singleton;
  StringAssets._();

  void loadStrings() async {
    termsOfService = await rootBundle.loadString(termsOfServiceFile);
    privacyPolicy = await rootBundle.loadString(privacyPolicyFile);
    nightScoutHelp = await rootBundle.loadString(nightScoutHelpFile);
  }

  static const String termsOfServiceFile = "assets/TERMS_OF_SERVICE.md";
  static const String privacyPolicyFile = "assets/PRIVACY_POLICY.md";
  static const String nightScoutHelpFile = "assets/NIGHTSCOUT_HELP.md";

  String termsOfService = "";
  String privacyPolicy = "";
  String nightScoutHelp = "";
}
