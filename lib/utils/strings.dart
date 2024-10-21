import 'dart:convert';

import 'package:carer/utils/logs.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/services.dart';

JsonDecoder decoder = const JsonDecoder();
JsonEncoder encoder = const JsonEncoder.withIndent('  ');

Map<String, dynamic>? decodeJson(String input) {
  try {
    return decoder.convert(input);
  } catch (e, stackTrace) {
    Errors.captureError(e, stackTrace, name: "decodeJson");
    return null;
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

String prettyPrintJson(String input) {
  try {
    var object = decoder.convert(input);
    var prettyString = encoder.convert(object);
    var str = "";
    prettyString.split('\n').forEach((element) => str += "$element\n");
    return str;
  } catch (e, stackTrace) {
    Errors.captureError(e, stackTrace, name: "prettyPrintJson");
    return input;
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
    termsAndConditions = await rootBundle.loadString(termsAndConditionsFile);
    privacyPolicy = await rootBundle.loadString(privacyPolicyFile);
  }

  static const String termsAndConditionsFile = "assets/TERMS_AND_CONDITIONS.md";
  static const String privacyPolicyFile = "assets/PRIVACY_POLICY.md";

  String termsAndConditions = "";
  String privacyPolicy = "";
}
