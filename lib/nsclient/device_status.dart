// This has the resivoir status which v2/properties does not have!
// v2/propertie s

import 'dart:convert';

class NSDeviceStatus {
  final double? reservoir;
  final bool? isCharging;
  final double? battery;
  final String raw;

  NSDeviceStatus({required this.reservoir, required this.isCharging, required this.battery, required this.raw});

  factory NSDeviceStatus.fromJson(Map<String, dynamic> json) {
    double? reservoir;
    bool? isCharging;
    double? battery;

    if (json["pump"] != null && json["pump"] is Map<String, dynamic> && json["pump"]["reservoir"] != null && json["pump"]["reservoir"] is num) {
      reservoir = json["pump"]["reservoir"].toDouble();
    }

    if (json["isCharging"] is bool) {
      isCharging = json["isCharging"];
    }

    if (json["uploaderBattery"] is num) {
      battery = json["uploaderBattery"].toDouble();
    }

    return NSDeviceStatus(
      reservoir: reservoir,
      isCharging: isCharging,
      battery: battery,
      raw: jsonEncode(json),
    );
  }
}
