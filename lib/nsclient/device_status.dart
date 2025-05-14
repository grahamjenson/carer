// This has the resivoir status which v2/properties does not have!
// v2/propertie s

import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';

class NSDeviceStatus {
  final double? reservoir;
  final bool? isCharging;
  final double? battery;
  final String raw;

  NSDeviceStatus({required this.reservoir, required this.isCharging, required this.battery, required this.raw});

  static NSDeviceStatus fromDeviceJson(String jsonString) {
    List<dynamic> jsonList = json.decode(jsonString);
    if (jsonList.isEmpty) {
      return NSDeviceStatus.fromJson({});
    }
    var firstElem = jsonList.first;
    if (firstElem is Map<String, dynamic>) {
      return NSDeviceStatus.fromJson(firstElem);
    }
    return NSDeviceStatus.fromJson({});
  }

  factory NSDeviceStatus.fromJson(Map<String, dynamic> json) {
    double? reservoir;
    bool? isCharging;
    double? battery;

    if (json["pump"] != null && json["pump"] is Map<String, dynamic> && json["pump"]["reservoir"] != null && json["pump"]["reservoir"] is num) {
      reservoir = NSType.getDouble(json["pump"]["reservoir"]);
    }

    if (json["isCharging"] is bool) {
      isCharging = json["isCharging"];
    }

    if (json["uploaderBattery"] is num) {
      battery = NSType.getDouble(json["uploaderBattery"]);
    }

    if (json["uploader"] != null &&
        json["uploader"] is Map<String, dynamic> &&
        json["uploader"]["battery"] != null &&
        json["uploader"]["battery"] is num) {
      battery = NSType.getDouble(json["uploader"]["battery"]);
    }

    return NSDeviceStatus(
      reservoir: reservoir,
      isCharging: isCharging,
      battery: battery,
      raw: jsonEncode(json),
    );
  }
}
