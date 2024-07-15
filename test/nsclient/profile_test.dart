import 'dart:io';

import 'package:carer/models/constants.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:test/test.dart';

import 'fixtures/files.dart';

void main() {
  test('NSProfile.fromJson should parse JSON and create NSProfile object', () async {
    final file = File(files["current_profile"]!);
    final jsonString = await file.readAsString();

    NSProfile profile = NSProfile.fromCurrentJson(jsonString)!;

    expect(profile.dia, 6);
    expect(profile.name, "SamDash-2023-11SMB");
    expect(profile.id, "668fbca35de9b880531dad48");
    expect(profile.carbratio.values.length, 6);
    expect(profile.carbratio.values.first.value, 20);

    expect(profile.sens.values.length, 6);
    expect(profile.sens.values.first.value, 20);

    expect(profile.basal.values.length, 24);
    expect(profile.basal.values.first.value, 0.2);

    expect(profile.targetLow.values.length, 5);
    expect(profile.targetLow.values.first.value, 5.5 * MGtoMMOL);

    expect(profile.targetHigh.values.length, 5);
    expect(profile.targetHigh.values.first.value, 7 * MGtoMMOL);
  });
}
