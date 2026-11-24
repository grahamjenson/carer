import 'dart:convert';

import 'package:carer/mappers/sql/carbs.dart';
import 'package:carer/mappers/sql/temptarget.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/collection_updaters/treatments.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:clock/clock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import '../test_utils.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  agroup("history", () {
    atest("a history page's deleted documents are not read as treatments, and give their identifiers", () async {
      var page = jsonEncode({
        "status": 200,
        "result": [
          {"identifier": "carbs-kept", "eventType": "Carb Correction", "carbs": 5, "date": clock.minutesAgo(30).millisecondsSinceEpoch, "srvModified": 2000, "isValid": true},
          {"identifier": "carbs-deleted", "eventType": "Carb Correction", "carbs": 23, "date": clock.minutesAgo(40).millisecondsSinceEpoch, "srvModified": 2001, "isValid": false},
        ]
      });
      var treatments = NSTreatments.fromJson(page);
      expect(treatments.carbs.map((c) => c.id), ["carbs-kept"]);
      expect(treatments.deletedIds, ["carbs-deleted"]);
      expect(treatments.lastSrvModified, 2001);
      expect(treatments.count, 2);
    });

    atest("an entries history page gives its deleted readings and its last change", () async {
      var page = jsonEncode({
        "status": 200,
        "result": [
          {"identifier": "sgv-kept", "type": "sgv", "sgv": 120, "date": clock.minutesAgo(30).millisecondsSinceEpoch, "srvModified": 3000},
          {"identifier": "sgv-deleted", "type": "sgv", "sgv": 40, "date": clock.minutesAgo(35).millisecondsSinceEpoch, "srvModified": 3001, "isValid": false},
        ]
      });
      var entries = NSEntries.fromJson(page);
      expect(entries.entries.map((e) => e.id), ["sgv-kept"]);
      expect(entries.deletedIds, ["sgv-deleted"]);
      expect(entries.lastSrvModified, 3001);
    });

    // As in the AAPS ↔ Nighttroop ↔ T1D Carer test: a temp target cut 11 minutes into its 45, carbs deleted, and carbs
    // entered offline 12 minutes before they were uploaded, all older than the 10 minutes a search by date read
    atest("an update applies changes and deletions to old treatments, and treatments uploaded late", () async {
      var start = clock.minutesAgo(30);
      await NSTreatmentsUpdater().processTreatments(NSTreatments.fromJson(jsonEncode({
        "result": [
          {"identifier": "tt-cut", "eventType": "Temporary Target", "targetBottom": 140, "targetTop": 140, "duration": 45, "date": start.millisecondsSinceEpoch},
          {"identifier": "carbs-deleted", "eventType": "Carb Correction", "carbs": 23, "date": clock.minutesAgo(40).millisecondsSinceEpoch},
          {"identifier": "carbs-edited", "eventType": "Carb Correction", "carbs": 10, "date": clock.minutesAgo(50).millisecondsSinceEpoch},
        ]
      })));

      List<Uri> asked = [];
      NSClient().http = MockClient((request) async {
        asked.add(request.url);
        if (request.url.path.contains("/api/v2/authorization/request")) {
          return Response(jsonEncode({"token": "jwt", "exp": clock.hoursFromNow(1).millisecondsSinceEpoch ~/ 1000}), 200);
        }
        return Response(
            jsonEncode({
              "status": 200,
              "result": [
                {"identifier": "tt-cut", "eventType": "Temporary Target", "targetBottom": 140, "targetTop": 140, "duration": 11, "date": start.millisecondsSinceEpoch, "srvModified": 1001},
                {"identifier": "carbs-deleted", "eventType": "Carb Correction", "carbs": 23, "date": clock.minutesAgo(40).millisecondsSinceEpoch, "srvModified": 1002, "isValid": false},
                {"identifier": "carbs-edited", "eventType": "Carb Correction", "carbs": 15, "date": clock.minutesAgo(50).millisecondsSinceEpoch, "srvModified": 1003},
                {"identifier": "carbs-late", "eventType": "Carb Correction", "carbs": 5, "date": clock.minutesAgo(12).millisecondsSinceEpoch, "srvModified": 1004},
              ]
            }),
            200);
      });
      SecureSettings().nightscoutURL = "https://carertest.example.nz";
      SecureSettings().nightscoutToken = "carertest-token";

      expect(await NSTreatmentsUpdater().update(1000), true);
      expect(asked.where((u) => u.path == "/api/v3/treatments/history/1000"), isNotEmpty);

      var tt = await SQLToTempTarget().query(conditions: {"eid = ?": "tt-cut"});
      expect(tt.single.duration, 11 * 60);
      expect(await SQLToCarbs().query(conditions: {"eid = ?": "carbs-deleted"}), isEmpty);
      expect((await SQLToCarbs().query(conditions: {"eid = ?": "carbs-edited"})).single.value, 15);
      expect((await SQLToCarbs().query(conditions: {"eid = ?": "carbs-late"})).single.value, 5);
    });
  });
}
