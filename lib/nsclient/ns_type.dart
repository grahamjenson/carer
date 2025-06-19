import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';

abstract class NSType {
  // The data can be a bit shaky with what is available, so just try to use the date, then the created at.
  static DateTime getBestGuessDate(json) {
    DateTime? createdAtMaybe;
    if (json["date"] != null) {
      // date can be a double.
      createdAtMaybe = DateTime.fromMillisecondsSinceEpoch(json['date'].toInt());
    }

    if (json["created_at"] != null && createdAtMaybe == null) {
      createdAtMaybe = trygo(() => DateTime.parse(json['created_at']));
    }

    return createdAtMaybe ?? clock.now();
  }

  // Basic Type Conversions
  static double? getDouble(dynamic value, {double? defaultValue}) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? getInt(dynamic value, {int? defaultValue}) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.round();
    } else if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static bool? getBool(dynamic value, {bool? defaultValue}) {
    if (value is bool) {
      return value;
    } else if (value is String) {
      return bool.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static String? getString(dynamic value, {String? defaultValue}) {
    if (value is String) {
      return value;
    } else if (value is int || value is double || value is bool) {
      return value.toString();
    }
    return defaultValue;
  }

  static double? getDoubleFromJson(Map<String, dynamic> json, List<String> keys, {double? defaultValue}) {
    // recursive depth search for a value
    var key = keys.first;
    keys = keys.sublist(1);
    if (keys.isEmpty) {
      return getDouble(json[key], defaultValue: defaultValue);
    }

    if (!json.containsKey(key) || json[key] is! Map<String, dynamic>) {
      return defaultValue;
    }

    json = json[key] as Map<String, dynamic>;
    if (json.isEmpty) {
      return defaultValue;
    }

    // continue searching in the next level
    return getDoubleFromJson(json, keys);
  }

  static int? getIntFromJson(Map<String, dynamic> json, List<String> keys, {int? defaultValue}) {
    var key = keys.first;
    keys = keys.sublist(1);
    if (keys.isEmpty) {
      return getInt(json[key], defaultValue: defaultValue);
    }

    if (!json.containsKey(key) || json[key] is! Map<String, dynamic>) {
      return defaultValue;
    }

    json = json[key] as Map<String, dynamic>;
    if (json.isEmpty) {
      return defaultValue;
    }

    // continue searching in the next level
    return getIntFromJson(json, keys);
  }

  static bool? getBoolFromJson(Map<String, dynamic> json, List<String> keys, {bool? defaultValue}) {
    // recursive depth search for a value
    var key = keys.first;
    keys = keys.sublist(1);
    if (keys.isEmpty) {
      return getBool(json[key], defaultValue: defaultValue);
    }

    if (!json.containsKey(key) || json[key] is! Map<String, dynamic>) {
      return defaultValue;
    }
    json = json[key] as Map<String, dynamic>;
    if (json.isEmpty) {
      return defaultValue;
    }

    // continue searching in the next level
    return getBoolFromJson(json, keys);
  }

  static String? getStringFromJson(Map<String, dynamic> json, List<String> keys, {String? defaultValue}) {
    // recursive depth search for a value
    var key = keys.first;
    keys = keys.sublist(1);
    if (keys.isEmpty) {
      return getString(json[key], defaultValue: defaultValue);
    }

    if (!json.containsKey(key) || json[key] is! Map<String, dynamic>) {
      return defaultValue;
    }
    json = json[key] as Map<String, dynamic>;
    if (json.isEmpty) {
      return defaultValue;
    }

    // continue searching in the next level
    return getStringFromJson(json, keys);
  }
}
