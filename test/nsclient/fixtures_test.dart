import 'dart:io';

import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/device_status.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/properties.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'fixtures/files.dart';

typedef parserFn<T> = T Function(String);
typedef testFn<T> = void Function(T);

class FixtureTest<T> {
  final String filename;
  final parserFn<T> parser;
  testFn<T>? test;

  FixtureTest(this.filename, this.parser, {this.test});

  T? tests() {
    T val = parser(File(getFile()).readAsStringSync());

    if (test != null) {
      test!(val);
    }

    return val;
  }

  String getFile() {
    return files[filename]!;
  }
}

void main() {
  profileParserNoNull(String str) {
    var eprofile = NSProfile.fromJson("empty", "", clock.now(), {});
    try {
      return NSProfile.fromCurrentJson(str) ?? eprofile;
    } catch (e) {}
    return eprofile;
  }

  List<FixtureTest> tests = [
    // Treatments
    FixtureTest<NSTreatments>(
      'treatments',
      NSTreatments.fromJson,
      test: (NSTreatments treatments) {
        expect(treatments.length, 11);
        expect(treatments[0], isA<NSTreatmentTempBasal>());
      },
    ),

    FixtureTest<NSTreatments>('treatments_bad', NSTreatments.fromJson, test: (NSTreatments treatments) {
      expect(treatments.length, 0);
    }),

    // Entries
    FixtureTest<NSEntries>('entries', NSEntries.fromJson, test: (NSEntries entries) {
      expect(entries.length, 4);
      expect(entries[0].sgv, 103);
    }),

    FixtureTest<NSEntries>('entries_bad', NSEntries.fromJson, test: (NSEntries entries) {
      expect(entries.length, 0);
    }),

    // Current Profile
    FixtureTest<NSProfile>('current_profile', profileParserNoNull, test: (NSProfile profile) {
      expect(profile.name, "currentProfileName");
      expect(profile.dia, 6);

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
    }),

    FixtureTest<NSProfile>('current_profile_bad', profileParserNoNull, test: (NSProfile profile) {
      expect(profile.name, "empty");
    }),

    // Properties
    FixtureTest<NSProperties>('properties', NSProperties.fromJson, test: (NSProperties properties) {
      expect(properties, isNotNull);
      expect(properties.battery, equals(87));
      expect(properties.batteryDisplay, equals("87%"));
      expect(properties.iob, equals(1.737));
      expect(properties.basaliob, equals(-0.632));
      expect(properties.treatmentIob, equals(3.264));
      expect(properties.cob, equals(9.39056953071084));
      expect(properties.cannulaChangeTime, equals(1722497000000));
      expect(properties.sensorChangeTime, equals(1722498000000));
    }),

    FixtureTest<NSProperties>('properties_bad', NSProperties.fromJson, test: (NSProperties properties) {
      expect(properties, isNotNull);
      expect(properties.battery, isNull);
      expect(properties.batteryDisplay, isNull);
      expect(properties.iob, isNull);
      expect(properties.basaliob, isNull);
      expect(properties.treatmentIob, isNull);
      expect(properties.cob, isNull);
      expect(properties.cannulaChangeTime, isNull);
      expect(properties.sensorChangeTime, isNull);
    }),

    // device status
    FixtureTest<NSDeviceStatus>('devicestatus', NSDeviceStatus.fromDeviceJson, test: (NSDeviceStatus status) {
      expect(status, isNotNull);
      expect(status.battery, equals(84.0));
      expect(status.isCharging, false);
      expect(status.reservoir, 36.0);
    }),
    FixtureTest<NSDeviceStatus>('devicestatus_bad', NSDeviceStatus.fromDeviceJson, test: (NSDeviceStatus status) {
      expect(status, isNotNull);
      expect(status.battery, isNull);
      expect(status.isCharging, isNull);
      expect(status.reservoir, isNull);
    }),
  ];

  agroup('Fixtures', () async {
    for (var test in tests) {
      atest('Fixture Test For ${test.filename}', () async {
        var parsed = test.tests();
        expect(parsed, isNotNull);
      });
    }
  });
}
