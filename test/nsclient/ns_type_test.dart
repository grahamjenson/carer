import 'package:carer/nsclient/ns_type.dart';
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
  });
}
