import 'dart:convert';

import 'package:carer/utils/logs.dart';

JsonDecoder decoder = const JsonDecoder();
JsonEncoder encoder = const JsonEncoder.withIndent('  ');

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
