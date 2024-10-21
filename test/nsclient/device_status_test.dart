import 'dart:convert';
import 'dart:io';

import 'package:carer/nsclient/device_status.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

void main() async {
  await sqfliteTestInit();

  test('NSDeviceStatus JSON parsing test', () async {
    final file = File(files["devicestatus"]!);
    final jsonString = await file.readAsString();
    List<dynamic> jsonList = jsonDecode(jsonString);
    NSDeviceStatus? properties = NSDeviceStatus.fromJson(jsonList.first);
    expect(properties, isNotNull);
    expect(properties.battery, equals(84.0));
    expect(properties.isCharging, false);
    expect(properties.reservoir, 36.0);
  });

  test('parsing bad NSDeviceStatus return enmpty NSDeviceStatus object', () async {
    NSDeviceStatus? properties = NSDeviceStatus.fromJson({});

    expect(properties, isNotNull);
    expect(properties.battery, isNull);
    expect(properties.isCharging, isNull);
    expect(properties.reservoir, isNull);
  });
}
