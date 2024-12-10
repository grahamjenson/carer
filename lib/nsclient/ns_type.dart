import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';

abstract class NSType {
  static DateTime getCreatedAtDate(json) {
    DateTime? createdAtMaybe;
    if (json["created_at"] != null) {
      createdAtMaybe = trygo(() => DateTime.parse(json['created_at']));
    }
    if (json["date"] != null && createdAtMaybe == null) {
      createdAtMaybe = DateTime.fromMillisecondsSinceEpoch(json['date']);
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
