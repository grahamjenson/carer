// ignore_for_file: non_constant_identifier_names

import 'package:carer/models/details/alarms/alarms.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() async {
  agroup("AlarmsWHarness", () {
    // Want to be explicit about the values
    int URGENTHIGH = 200;

    int HIGH = 180;
    int HIGHMINUTES = 20;

    int LOW = 70;
    int LOWPREDICIONTMINUTES = 10;
    int URGENTLOW = 50;

    int FASTRISE = 10;
    int FASTRISEMINUTES = 10;

    int FASTDROP = -10;
    int FASTDROPMINUTES = 10;

    int NODATAMINUTES = 20;

    // EXAMPLE
    int INRANGE = 80;

    setUp(() {
      // Turn on all alarms
      AlarmSettings().urgentLowAlarm = true;
      AlarmSettings().lowAlarm = true;
      AlarmSettings().highAlarm = true;
      AlarmSettings().urgentHighAlarm = true;
      AlarmSettings().lowPredictionAlarm = true;
      AlarmSettings().carerBatteryAlarm = true;
      AlarmSettings().t1dBatteryAlarm = true;
      AlarmAlertSettings().smartSnoozeHigh = true;

      AlarmSettings().fastRiseAlarmMinutes = FASTRISEMINUTES;
      AlarmSettings().fastDropAlarmMinutes = FASTDROPMINUTES;
      AlarmSettings().noDataAlarmMinutes = NODATAMINUTES;
      AlarmSettings().lowPredictionMinutes = LOWPREDICIONTMINUTES;
      AlarmSettings().highMinutes = HIGHMINUTES;

      TargetSettings().highUrgent = URGENTHIGH.toDouble();
      TargetSettings().highTarget = HIGH.toDouble();
      TargetSettings().lowTarget = LOW.toDouble();
      TargetSettings().lowUrgent = URGENTLOW.toDouble();
      TargetSettings().fastRiseDelta = FASTRISE.toDouble();
      TargetSettings().fastDropDelta = FASTDROP.toDouble();
    });

    var tests = [
      // NEGATIVE CASES
      AlarmTest(
        "Blank Data",
        sgvs: [INRANGE, null, null, null],
        expectedAlarms: {}, // predictive low
      ),
      AlarmTest(
        "Normal operation",
        sgvs: [INRANGE, INRANGE, INRANGE, INRANGE],
        expectedAlarms: {},
      ),
      AlarmTest(
        "Limited Data Fast Drop Ignored",
        sgvs: [HIGH - 10, HIGH - 30, HIGH - 50, null],
        expectedAlarms: {},
      ),
      AlarmTest(
        "Not High Enough",
        sgvs: [INRANGE, INRANGE, HIGH + 10, HIGH + 10],
        expectedAlarms: {},
      ),
      //
      //
      // POSITIVE ALARM CASES
      //
      AlarmTest(
        "Predictive Alarm triggering",
        sgvs: [LOW + 40, LOW + 20, LOW + 1],
        expectedAlarms: {AlarmType.low, AlarmType.fastDrop}, // predictive low
      ),
      AlarmTest(
        "Blank Data Causing No Data Alarm",
        sgvs: [INRANGE, null, null, null, null],
        expectedAlarms: {AlarmType.noData}, // predictive low
      ),
      AlarmTest(
        "Fast Drop",
        sgvs: [HIGH - 10, HIGH - 30, HIGH - 50],
        expectedAlarms: {AlarmType.fastDrop},
      ),
      AlarmTest(
        "Fast Rise",
        sgvs: [LOW + 10, LOW + 30, LOW + 50],
        expectedAlarms: {AlarmType.fastRise},
      ),
      AlarmTest(
        "Urgent High",
        sgvs: [INRANGE, INRANGE, URGENTHIGH + 10],
        expectedAlarms: {AlarmType.urgentHigh},
      ),
      AlarmTest(
        "Urgent Low",
        sgvs: [URGENTLOW - 10],
        expectedAlarms: {AlarmType.urgentLow, AlarmType.low},
      ),

      AlarmTest(
        "Low",
        sgvs: [LOW - 10],
        expectedAlarms: {AlarmType.low},
      ),
      AlarmTest(
        "HIGH",
        sgvs: [INRANGE, HIGH + 10, HIGH + 10, HIGH + 10, HIGH + 10],
        expectedAlarms: {AlarmType.high},
      ),
    ];

    for (var t in tests) {
      atest("${t.name} est ${tests.indexOf(t)}", () async {
        // Pre-Test
        expect(AlarmType.triggeredAlarms(), <AlarmType>{});
        expect(AlarmType.activeAlarms(), AlarmType.values.toSet()..removeAll([AlarmType.test, AlarmType.unknown]));
        expect(AlarmType.smartSnoozeAlarms(), <AlarmType>{});

        await createSGVsInOrder(t.sgvs, offset: min2);

        Set<AlarmType> triggeredAlarms = {};
        for (var alarm in AlarmType.values) {
          var (triggered, active, smartSnooze) = alarm.alarmStatus();
          if (triggered) {
            triggeredAlarms.add(alarm);
          }

          // just checking for errors here
          expect(alarm.description, isNotNull);
          expect(alarm.title, isNotNull);
          expect(alarm.shortSummary, isNotNull);
          expect(alarm.statment, isNotNull);
        }
        expect(triggeredAlarms, t.expectedAlarms);
      });
    }
  });
}

class AlarmTest {
  List<int?> sgvs;
  Set<AlarmType> expectedAlarms;
  String name;
  AlarmTest(this.name, {required this.sgvs, required this.expectedAlarms});
}
