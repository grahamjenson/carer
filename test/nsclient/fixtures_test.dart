import 'dart:io';

import 'package:carer/models/sql/constants.dart';
import 'package:carer/nsclient/device_status.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/properties.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';
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
  (NSProfile?, List<NSProfile>) profileParserNoNull(String str) {
    try {
      return NSProfile.fromCurrentJson(str);
    } catch (e) {}
    return (null, <NSProfile>[]);
  }

  List<FixtureTest> tests = [
    // Treatments
    FixtureTest<NSTreatments>(
      'treatments',
      NSTreatments.fromJson,
      test: (NSTreatments treatments) {
        expect(treatments.length, 13);
        expect(treatments[0], isA<NSTreatmentInsulin>());
        var t0 = treatments[0] as NSTreatmentInsulin;
        expect(t0.insulin, 0.05);

        expect(treatments[1], isA<NSTemporaryTarget>());
        var t1 = treatments[1] as NSTemporaryTarget;
        expect(t1.durationInMilliseconds, 21600000);

        expect(treatments[10], isA<NSTreatmentTempBasal>());
        var t11 = treatments[10] as NSTreatmentTempBasal;
        expect(t11.absolute, 1.55);
        expect(t11.durationInMilliseconds, (4.1 * 60 * 1000).round());
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
    FixtureTest<(NSProfile?, List<NSProfile>)>('current_profile', profileParserNoNull, test: ((NSProfile?, List<NSProfile>) profileProfiles) {
      var (profile, profiles) = profileProfiles;
      if (profile == null) {
        fail("Profile should not be null");
      }
      expect(profiles, isNotNull);
      expect(profiles.length, 1);

      expect(profile.name, "currentProfileName");
      expect(profile.dia, 6);

      expect(profile.id, "668fbca35de9b880531dad48_currentProfileName");
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

    FixtureTest<(NSProfile?, List<NSProfile>)>('current_profile_loop', profileParserNoNull, test: ((NSProfile?, List<NSProfile>) profileProfiles) {
      var (profile, profiles) = profileProfiles;
      if (profile == null) {
        fail("Profile should not be null");
      }

      expect(profiles.length, 0);

      expect(profile.name, "loopProfile");
    }),

    FixtureTest<(NSProfile?, List<NSProfile>)>('current_profile_bad', profileParserNoNull, test: ((NSProfile?, List<NSProfile>) profileProfiles) {
      var (profile, profiles) = profileProfiles;
      expect(profile, isNull);
      expect(profiles.length, 0);
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

    FixtureTest<NSProperties>('properties_loop', NSProperties.fromJson, test: (NSProperties properties) {
      expect(properties, isNotNull);
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

    FixtureTest<NSDeviceStatus>('devicestatus_loop', NSDeviceStatus.fromDeviceJson, test: (NSDeviceStatus status) {
      expect(status, isNotNull);
      expect(status.battery, equals(80.0));
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
