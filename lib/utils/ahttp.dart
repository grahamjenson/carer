import 'dart:io';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart';

class Ahttp {
  static Client getClient() {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoClient.fromSessionConfiguration(URLSessionConfiguration.ephemeralSessionConfiguration());
    }
    return Client();
  }
}
