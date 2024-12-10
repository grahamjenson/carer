import 'dart:convert';

import 'package:carer/nsclient/device_status.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/properties.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

String toNSDateString(DateTime dt) {
  dt = dt.toUtc();
  var year = dt.year;
  var month = dt.month.toString().padLeft(2, '0');
  var day = dt.day.toString().padLeft(2, '0');
  var hour = dt.hour.toString().padLeft(2, '0');
  var minute = dt.minute.toString().padLeft(2, '0');
  return "$year-$month-${day}T$hour:$minute";
}

Uri testEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/summary.json?token=$token');

Uri entryEndpoint(nsURL, token, DateTime gteCreatedAt) =>
    Uri.parse('$nsURL/api/v1/entries.json?token=$token&find[dateString][\$gte]=${toNSDateString(gteCreatedAt)}&count=1000');

Uri treatmentsEndpoint(nsURL, token, DateTime gteCreatedAt) =>
    Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[created_at][\$gte]=${toNSDateString(gteCreatedAt)}&count=1000');

Uri treatmentsProfileSwitch(nsURL, token, int count) =>
    Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[eventType]=Profile+Switch&count=$count');
Uri treatmentsNote(nsURL, token, int count) => Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[eventType]=Note&count=$count');

Uri currentProfile(nsURL, token) => Uri.parse('$nsURL/api/v1/profile/current.json?token=$token');

Uri propertiesEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties.json?token=$token');

Uri deviceStatusEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v1/devicestatus.json?token=$token&count=1');

// Add Carbs endpoint
Uri v3TreatmentsEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v3/treatments');

// JWT endpoint
Uri jwtEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/authorization/request/token=$token');

// Singleton
class NSClient {
  static final NSClient _singleton = NSClient._internal();
  factory NSClient() => _singleton;
  NSClient._internal();

  ASignal<DateTime?> lastError = ASignal<DateTime?>(null, debugLabel: "NSClientLastError");
  ASignal<DateTime?> lastFetched = ASignal<DateTime?>(null, debugLabel: "NSClientLastCalled");

  String? jwt;
  DateTime? jwtExpire;

  ///
  // Test API Call
  ///

  Future<String?> testNSUrlAndToken(String nsURL, String token) async {
    if (nsURL.isEmpty || nsURL.length < 8) {
      return "NightScout URL not valid";
    }
    if (token.isEmpty || nsURL.length < 10) {
      return "NightScout Token not valid";
    }

    var ep = testEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (err != null || response == null) {
      return "Error: $err";
    }
    if (response.statusCode != 200) {
      return "Bad Response: ${response.body}";
    }
    return null;
  }

  ///
  // API V3 Calls
  ////

  Future<bool> refreshJWT(String nsURL, String token) async {
    // check to see if we need a new JWT
    if (jwt != null && jwtExpire != null && jwtExpire!.isAfter(clock.now().add(const Duration(minutes: 5)))) {
      return true;
    }

    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return false;
    }
    alog("NSCLIENT: REFRESHING JWT");
    var ep = jwtEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return false;
    }

    // expample
    // {"token":"<t>>",
    // "sub":"display",
    // "permissionGroups":[["api:treatments:create"],["*:*:read"],[]],
    // "iat":1728938573,
    // "exp":1728967373}
    var body = jsonDecode(response!.body);
    jwt = body["token"] as String;
    var expts = body["exp"] as int;
    jwtExpire = DateTime.fromMillisecondsSinceEpoch(expts * 1000);
    return true;
  }

  Future<bool> addCarbs(String nsURL, String token, int carbs) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return false;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return false;
    }

    var ep = v3TreatmentsEndpoint(nsURL, token);

    var date = clock.now();
    var dateInMilliseconds = date.millisecondsSinceEpoch;

    Map<String, dynamic> bodyMap = {
      "eventType": "Carb Correction",
      "carbs": carbs,
      "date": dateInMilliseconds,
      "mills": dateInMilliseconds, // NightGuard requires this ¯\_(ツ)_/¯
      "isValid": true,
      "app": "carer",
    };

    final (response, err) = await go(http.post(ep,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Accept": " application/json",
          "Authorization": "bearer $jwt",
        },
        body: jsonEncode(bodyMap)));

    if (_handleResponseError(ep, response, err)) {
      return false;
    }

    return true;
  }

  Future<bool> addTempTarget(String nsURL, String token, int low, int high, int duration, String reason) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return false;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return false;
    }

    var ep = v3TreatmentsEndpoint(nsURL, token);

    var date = clock.now();
    var dateInMilliseconds = date.millisecondsSinceEpoch;

    Map<String, dynamic> bodyMap = {
      "eventType": "Temporary Target",
      "reason": reason,
      "targetBottom": low,
      "targetTop": high,
      "units": "mg/dl",
      "duration": duration, // In minutes
      "durationInMilliseconds": duration * 60 * 1000, // ms
      "date": dateInMilliseconds,
      "mills": dateInMilliseconds, // NightGuard requires this ¯\_(ツ)_/¯
      "isValid": true,
      "app": "carer",
    };

    final (response, err) = await go(http.post(ep,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Accept": " application/json",
          "Authorization": "bearer $jwt",
        },
        body: jsonEncode(bodyMap)));

    if (_handleResponseError(ep, response, err)) {
      return false;
    }

    return true;
  }

  ///
  // API  V1 CALLS
  ///

  Future<NSEntries> getEntries(String nsURL, String token, DateTime gteCreateAt) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return NSEntries.empty();
    }
    var ep = entryEndpoint(nsURL, token, gteCreateAt);

    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return NSEntries.empty();
    }

    return NSEntries.fromJson(response!.body);
  }

  Future<NSTreatments> getTreatments(String nsURL, String token, DateTime gteCreateAt) async {
    if (nsURL == "" || token == "") {
      return NSTreatments.empty();
    }
    var ep = treatmentsEndpoint(nsURL, token, gteCreateAt);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response!.body);
  }

  Future<NSProfile?> getCurrentProfile(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getCurrentProfile No NS URL");
      return null;
    }
    var ep = currentProfile(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return null;
    }

    return NSProfile.fromCurrentJson(response!.body);
  }

  Future<NSProperties?> getProperties(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getProperties No NS URL");
      return null;
    }
    var ep = propertiesEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return null;
    }

    return NSProperties.fromJson(response!.body);
  }

  Future<NSDeviceStatus?> getDeviceStatus(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getDeviceStatus No NS URL");
      return null;
    }
    var ep = deviceStatusEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return null;
    }

    return NSDeviceStatus.fromDeviceJson(response!.body);
  }

  bool _handleResponseError(Uri uri, Response? response, Object? err) {
    if (err != null || response == null) {
      lastError.value = clock.now();
      ToastService().showError("Nightscout Error", description: err.toString());
      return true;
    }
    alog("NSCLIENT: FETCHED ${uri.toString()}");
    if (response.statusCode != 200 && response.statusCode != 201) {
      lastError.value = clock.now();
      alog("NSCLIENT: NON 200 responce code ${response.statusCode}");

      String body = response.body;
      var json = decodeJson(response.body);
      if (json != null) {
        if (json.containsKey("message") && json.containsKey("description")) {
          body = "${json["message"]} - ${json["description"]}";
        } else if (json.containsKey("message")) {
          body = json["message"];
        }
      }

      ToastService().showError("Nightscout Error: Bad Response Code", description: "${response.statusCode}: $body");
      return true;
    }
    lastFetched.value = clock.now();
    return false;
  }
}
