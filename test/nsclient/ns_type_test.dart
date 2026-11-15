import 'package:carer/nsclient/ns_type.dart';
import 'package:carer/utils/env.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup("get", () {
    atest("NSType.getDoubleFromJson", () async {
      var json = {
        "key1": 1.0,
        "key2": 2.0,
        "key3": null,
        "key4": "not a number",
        "key5": {"key50": 3.0, "key51": "not a number"},
        "key6": {
          "key60": {"key61": 4.0}
        },
        "key7": {}
      };

      expect(NSType.getDoubleFromJson(json, ["key1"]), 1.0);
      expect(NSType.getDoubleFromJson(json, ["key2"]), 2.0);
      expect(NSType.getDoubleFromJson(json, ["key3"]), null);
      expect(NSType.getDoubleFromJson(json, ["key4"]), null);
      expect(NSType.getDoubleFromJson(json, ["key5", "key50"]), 3.0);
      expect(NSType.getDoubleFromJson(json, ["key5", "key51"]), null);
      expect(NSType.getDoubleFromJson(json, ["key6", "key60", "key61"]), 4.0);
      expect(NSType.getDoubleFromJson(json, ["key7", "key60"]), null);
    });

    atest("NSType.getBestGuessDate", () async {
      var json1 = {
        "date": 1625079600000, // July 1, 2021
        "created_at": "2022-06-30T12:00:00Z"
      };
      var json2 = {"created_at": "2021-06-30T12:00:00Z"};
      var json3 = {};
      var json4 = {"date": null, "created_at": null};
      var json5 = {"date": "invalid date", "created_at": "also invalid"};
      var json6 = {"created_at": "٢٠٢٥-١٢-٢٤T٢٢:٤٨:٢٧.٤٩٤Z"}; // Arabic numerals

      var date1 = NSType.getBestGuessDate(json1);
      var date2 = NSType.getBestGuessDate(json2);
      var date3 = NSType.getBestGuessDate(json3);

      // This will not throw errors because we expect them
      Env.catchErrors = false;
      var date4 = NSType.getBestGuessDate(json4);
      var date5 = NSType.getBestGuessDate(json5);
      Env.catchErrors = true;

      var date6 = NSType.getBestGuessDate(json6);

      expect(date1, DateTime.fromMillisecondsSinceEpoch(1625079600000));
      expect(date2, DateTime.parse("2021-06-30T12:00:00Z"));
      expect(date3, overrideNow); // should be now
      expect(date4, overrideNow); // should be now
      expect(date5, overrideNow); // should be now
      expect(date6, DateTime.parse("2025-12-24T22:48:27.494Z"));
    });
  });
}
