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
    double? reservoir = NSType.getDoubleFromJson(json, ["pump", "reservoir"]);
    bool? isCharging = NSType.getBoolFromJson(json, ["isCharging"]);

    double? battery = NSType.getDoubleFromJson(json, ["uploader", "battery"]);
    battery ??= NSType.getDoubleFromJson(json, ["uploaderBattery"]);

    return NSDeviceStatus(
      reservoir: reservoir,
      isCharging: isCharging,
      battery: battery,
      raw: jsonEncode(json),
    );
  }
}
