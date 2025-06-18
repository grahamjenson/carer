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
    try {
      if (json['upbat'] is Map && json['upbat']['min'] is Map && json['upbat']['min']['battery'] is num) {
        return (json['upbat']['min']['battery'] as num).toInt();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static String? getBatteryDisplay(Map<String, dynamic> json) {
    try {
      if (json['upbat'] is Map && json['upbat']['min'] is Map && json['upbat']['min']['display'] is String) {
        return json['upbat']['min']['display'] as String;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static double? getIOB(Map<String, dynamic> json) {
    try {
      if (json["openaps"] is Map && json["openaps"]["lastIOB"] is Map && json["openaps"]["lastIOB"]["iob"] is num) {
        return (json["openaps"]["lastIOB"]["iob"] as num).toDouble();
      }

      if (json["openaps"] is Map && json["openaps"]["lastSuggested"] is Map && json["openaps"]["lastSuggested"]["IOB"] is num) {
        return (json["openaps"]["lastSuggested"]["IOB"] as num).toDouble();
      }

      if (json["iob"] is Map && json["iob"]["iob"] is num) {
        return (json["iob"]["iob"] as num).toDouble();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static double? getTreatmentIOB(Map<String, dynamic> json) {
    try {
      if (json["iob"] is Map && json["iob"]["treatmentIob"] is num) {
        return (json["iob"]["treatmentIob"] as num).toDouble();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static double? getBasalIOB(Map<String, dynamic> json) {
    try {
      if (json["openaps"] is Map && json["openaps"]["lastIOB"] is Map && json["openaps"]["lastIOB"]["basaliob"] is num) {
        return (json["openaps"]["lastIOB"]["basaliob"] as num).toDouble();
      }

      if (json["iob"] is Map && json["iob"]["basaliob"] is num) {
        return (json["iob"]["basaliob"] as num).toDouble();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static double? getCOB(Map<String, dynamic> json) {
    try {
      if (json["openaps"] is Map && json["openaps"]["lastSuggested"] is Map && json["openaps"]["lastSuggested"]["COB"] is num) {
        return (json["openaps"]["lastSuggested"]["COB"] as num).toDouble();
      }
      if (json["cob"] is Map && json["cob"]["cob"] is num) {
        return (json["cob"]["cob"] as num).toDouble();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static int? getCannulaChangeTime(Map<String, dynamic> json) {
    try {
      if (json["cage"] is Map && json["cage"]["treatmentDate"] is num) {
        return (json["cage"]["treatmentDate"] as num).toInt();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static int? getSensorChangeTime(Map<String, dynamic> json) {
    try {
      if (json["sage"] is Map && json["sage"]["Sensor Change"] is Map && json["sage"]["Sensor Change"]["treatmentDate"] is num) {
        return (json["sage"]["Sensor Change"]["treatmentDate"] as num).toInt();
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
