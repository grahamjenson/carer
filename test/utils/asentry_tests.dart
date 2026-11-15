import 'package:carer/utils/asentry_http_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup("AHttpSanitizer", () {
    atest("sanitizeUrl", () async {
      var dets = AHttpSanitizer.sanitizeUrl("https://asd.com/api/v1/entries") ?? AUrlDetails();
      expect(dets.urlOrFallback, "https://nsurl.com/api/v1/entries");
    });
  });
}
