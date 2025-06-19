// Incomplete parsing
// {
//   "upbat": {
//     "min": {
//       "battery": 87,
//       "value": 87,
//       "display": "87%",
//       "level": 75
//     }
//   },
//   "iob": {
//     "iob": 1.983,
//     "basaliob": -0.669,
//     "treatmentIob": 3.464
//   },
//   "cob": {
//     "cob": 12.39360495744192
//   },
//   "cage": {
//     "treatmentDate": 1722497240926,
//   },
//   "sage": {
//     "Sensor Start": {
//       "found": false
//     },
//     "Sensor Change": {
//       "treatmentDate": 1721978583000
//     },
//     "min": "Sensor Change"
//   }
// }

import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/utils/logs.dart';

class NSProperties {
  final int? battery;
  final String? batteryDisplay;
  final double? iob;
  final double? basaliob;
  final double? treatmentIob;
  final double? cob;
  final int? cannulaChangeTime;
  final int? sensorChangeTime;
  final String raw;

  NSProperties({
    required this.battery,
    required this.batteryDisplay,
    required this.iob,
    required this.basaliob,
    required this.treatmentIob,
    required this.cob,
    required this.sensorChangeTime,
    required this.cannulaChangeTime,
    required this.raw,
  });

  static NSProperties fromJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);
      if (json is! Map<String, dynamic>) {
        throw const FormatException("Invalid JSON format");
      }

      for (var key in json.keys) {
        if (json[key] is Map && json[key].isEmpty) {
          json[key] = null; // Convert empty maps to null
        }
      }

      return NSProperties(
        battery: getBattery(json),
        batteryDisplay: getBatteryDisplay(json),
        iob: getIOB(json),
        basaliob: getBasalIOB(json),
        treatmentIob: getTreatmentIOB(json),
        cob: getCOB(json),
        sensorChangeTime: getSensorChangeTime(json),
        cannulaChangeTime: getCannulaChangeTime(json),
        raw: jsonString,
      );
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return NSProperties(
        battery: null,
        batteryDisplay: null,
        iob: null,
        basaliob: null,
        treatmentIob: null,
        cob: null,
        sensorChangeTime: null,
        cannulaChangeTime: null,
        raw: jsonString,
      );
    }
  }

  static int? getBattery(Map<String, dynamic> json) {
    int? value = NSType.getIntFromJson(json, ['upbat', 'min', 'battery']);
    return value;
  }

  static String? getBatteryDisplay(Map<String, dynamic> json) {
    String? value = NSType.getStringFromJson(json, ['upbat', 'min', 'display']);
    return value;
  }

  static double? getIOB(Map<String, dynamic> json) {
    double? value = NSType.getDoubleFromJson(json, ["openaps", "lastIOB", "iob"]);
    if (value != null) {
      return value;
    }
    value = NSType.getDoubleFromJson(json, ["openaps", "lastSuggested", "IOB"]);
    if (value != null) {
      return value;
    }
    value = NSType.getDoubleFromJson(json, ["iob", "iob"]);
    if (value != null) {
      return value;
    }
    return value;
  }

  static double? getTreatmentIOB(Map<String, dynamic> json) {
    double? value = NSType.getDoubleFromJson(json, ["iob", "treatmentIob"]);
    if (value != null) {
      return value;
    }
    return value;
  }

  static double? getBasalIOB(Map<String, dynamic> json) {
    double? value = NSType.getDoubleFromJson(json, ["openaps", "lastIOB", "basaliob"]);
    if (value != null) {
      return value;
    }
    value = NSType.getDoubleFromJson(json, ["iob", "basaliob"]);
    if (value != null) {
      return value;
    }
    return value;
  }

  static double? getCOB(Map<String, dynamic> json) {
    double? value = NSType.getDoubleFromJson(json, ["openaps", "lastSuggested", "COB"]);
    if (value != null) {
      return value;
    }
    value = NSType.getDoubleFromJson(json, ["cob", "cob"]);
    if (value != null) {
      return value;
    }
    return value;
  }

  static int? getCannulaChangeTime(Map<String, dynamic> json) {
    int? value = NSType.getIntFromJson(json, ["cage", "treatmentDate"]);

    return value;
  }

  static int? getSensorChangeTime(Map<String, dynamic> json) {
    int? value = NSType.getIntFromJson(json, ["sage", "Sensor Change", "treatmentDate"]);
    return value;
  }
}
