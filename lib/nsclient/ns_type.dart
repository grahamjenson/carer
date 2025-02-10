import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';

abstract class NSType {
  // The data can be a bit shaky with what is available, so just try to use the date, then the created at.
  static DateTime getBestGuessDate(json) {
    DateTime? createdAtMaybe;
    if (json["date"] != null) {
      createdAtMaybe = DateTime.fromMillisecondsSinceEpoch(json['date']);
    }

    if (json["created_at"] != null && createdAtMaybe == null) {
      createdAtMaybe = trygo(() => DateTime.parse(json['created_at']));
    }

    return createdAtMaybe ?? clock.now();
  }

  static double? getDouble(dynamic value, {double? defaultValue}) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0;
    } else {
      return defaultValue;
    }
  }

  static int? getInt(dynamic value, {int? defaultValue}) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.round();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return defaultValue;
    }
  }
}
