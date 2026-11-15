// This has the resivoir status which v2/properties does not have!
// v2/propertie s

import 'dart:convert';

import 'package:carer/nsclient/ns_type.dart';

class NSDeviceStatus {
  final double? reservoir;
  final bool? isCharging;
  final double? battery;
  final String raw;

  final double? iob;
  final double? basaliob;
  final double? treatmentIob;
  final double? cob;

  NSDeviceStatus({
    required this.reservoir,
    required this.isCharging,
    required this.battery,
    required this.raw,
    required this.iob,
    required this.basaliob,
    required this.treatmentIob,
    required this.cob,
  });

  static NSDeviceStatus fromDeviceJson(String jsonStr) {
    final Map<String, dynamic> jsonObject = json.decode(jsonStr);
    final List<dynamic> jsonList = jsonObject['result'] ?? [];
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

    double? iob = NSType.getDoubleFromJson(json, ["iob", "iob"]);
    iob ??= NSType.getDoubleFromJson(json, ["openaps", "iob", "iob"]);
    iob ??= NSType.getDoubleFromJson(json, ["openaps", "iob"]);
    iob ??= NSType.getDoubleFromJson(json, ["loop", "iob"]);
    iob ??= NSType.getDoubleFromJson(json, ["loop", "iob", "iob"]);

    double? cob = NSType.getDoubleFromJson(json, ["cob", "cob"]);
    cob ??= NSType.getDoubleFromJson(json, ["openaps", "cob", "cob"]);
    cob ??= NSType.getDoubleFromJson(json, ["openaps", "COB"]);
    cob ??= NSType.getDoubleFromJson(json, ["openaps", "suggested", "COB"]);
    cob ??= NSType.getDoubleFromJson(json, ["loop", "cob", "cob"]);

    double? basaliob = NSType.getDoubleFromJson(json, ["iob", "basaliob"]);
    basaliob ??= NSType.getDoubleFromJson(json, ["openaps", "iob", "basaliob"]);
    basaliob ??= NSType.getDoubleFromJson(json, ["loop", "iob", "basaliob"]);

    double? treatmentIob = NSType.getDoubleFromJson(json, ["iob", "treatmentIob"]);
    treatmentIob ??= NSType.getDoubleFromJson(json, ["openaps", "iob", "treatmentIob"]);
    treatmentIob ??= NSType.getDoubleFromJson(json, ["loop", "iob", "treatmentIob"]);

    return NSDeviceStatus(
      reservoir: reservoir,
      isCharging: isCharging,
      battery: battery,
      iob: iob,
      basaliob: basaliob,
      treatmentIob: treatmentIob,
      cob: cob,
      raw: jsonEncode(json),
    );
  }
}
