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

  NSProperties({
    required this.battery,
    required this.batteryDisplay,
    required this.iob,
    required this.basaliob,
    required this.treatmentIob,
    required this.cob,
    required this.sensorChangeTime,
    required this.cannulaChangeTime,
  });

  static NSProperties? fromJson(String jsonString) {
    try {
      var json = jsonDecode(jsonString);

      return NSProperties(
        battery: json["upbat"]?["min"]?["battery"]?.toInt(),
        batteryDisplay: json["upbat"]?["min"]?["display"]?.toString(),
        iob: json["iob"]?["iob"]?.toDouble(),
        basaliob: json["iob"]?["basaliob"]?.toDouble(),
        treatmentIob: json["iob"]?["treatmentIob"]?.toDouble(),
        cob: json["cob"]?["cob"]?.toDouble(),
        sensorChangeTime: json["sage"]?["Sensor Change"]?["treatmentDate"]?.toInt(),
        cannulaChangeTime: json["cage"]?["treatmentDate"]?.toInt(),
      );
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
      return null;
    }
  }
}
