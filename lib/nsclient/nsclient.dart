import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:carer/nsclient/device_status.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/properties.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/utils/asentry_http_client.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
import 'package:clock/clock.dart';
import 'package:cupertino_http/cupertino_http.dart';
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

Uri testEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/authorization/request/token=$token');

Uri entryEndpoint(nsURL, token, DateTime gteCreatedAt) =>
    Uri.parse('$nsURL/api/v1/entries.json?token=$token&find[date][\$gte]=${gteCreatedAt.millisecondsSinceEpoch}&count=1000');

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

  static ASignal<int> totalErrors = ASignal<int>(0, debugLabel: "NSClientTotalErrors");
  static ASignal<DateTime?> lastFetched = ASignal<DateTime?>(null, debugLabel: "NSClientLastCalled");

  String? jwtURL;
  String? jwtToken;
  String? jwt;
  DateTime? jwtExpire;

  final Client _flutterClient = ASentryHttpClient(client: Client());
  Client? _realCupertinoClient;
  Client get _cupertinoClient {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      return _flutterClient; // If not on iOS or macOS, return the flutter client
    }

    if (_realCupertinoClient != null) {
      return _realCupertinoClient!;
    }
    // Create a new cupertino client with an ephemeral session configuration
    _realCupertinoClient =
        ASentryHttpClient(client: CupertinoClient.fromSessionConfiguration(URLSessionConfiguration.ephemeralSessionConfiguration()));
    return _realCupertinoClient!;
  }

  Client get http {
    // return normal client if in foreground
    // Give the state a little wiggle room since it might have just changed and we still want the default
    if (AppLifecycleService().stateResumed || AppLifecycleService().stateChanged10SecondsAgo) {
      return _flutterClient;
    }

    // App is in background

    // the cupertino client throws errors on 500 spamming error logging, dont know how to fix
    // But normal http client throws bad file descripor errors in background (or startup) https://github.com/dart-lang/http/issues/197
    // So we just use the cupertino client on background fetches
    // TODO: this is a bit of a hack
    if (Platform.isIOS || Platform.isMacOS) {
      return _cupertinoClient;
    }

    return _flutterClient;
  }

  ///
  // Test API Call
  ///
  ///
  Future<String?> testNSUrlAndToken(String nsURL, String token) async {
    if (nsURL.isEmpty || nsURL.length < 8) {
      return "NightScout URL not valid";
    }
    if (token.isEmpty || nsURL.length < 10) {
      return "NightScout Token not valid";
    }

    var ep = testEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep).timeout(const Duration(seconds: 3)));
    if (err != null || response == null) {
      if (err is TimeoutException) {
        return "Timeout: Could not connect to NightScout in 3 seconds";
      }
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
    alog("NSCLIENT: JWT MAYBE REFRESHING");
    // Bad URL or token
    if (nsURL == "" || token == "") {
      alog("NSCLIENT: JWT No NS URL or token");
      return false;
    }

    var refreshNow = await shouldRefreshJWT(nsURL, token);
    if (!refreshNow) {
      alog("NSCLIENT: JWT is still valid until $jwtExpire");
      return true;
    }

    alog("NSCLIENT: JWT REFRESHING");
    var ep = jwtEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError("refreshJWT", ep, response, err)) {
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
    var expiryWithWiggle = expts - 300;
    jwtExpire = DateTime.fromMillisecondsSinceEpoch(expiryWithWiggle * 1000);

    // Store the URL and token here
    jwtURL = nsURL;
    jwtToken = token;

    return true;
  }

  Future<bool> shouldRefreshJWT(String nsURL, String token) async {
    // If the JWT is null then we should refresh
    if (jwt == null || jwtExpire == null) {
      return true;
    }

    // If it is a new URL or token then refresh
    if (jwtURL != nsURL || jwtToken != token) {
      return true;
    }

    // If JWT is before now then no need to refresh
    if (jwtExpire!.isBefore(clock.now())) {
      return true;
    }

    return false;
  }

  Future<bool> addCarbs(String nsURL, String token, int carbs) async {
    if (nsURL == "" || token == "") {
      alog("NSError: addCarbs No NS URL or token");
      return false;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      alog("NSError: addCarbs jwt refresh failed");
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

    if (_handleResponseError("addCarbs", ep, response, err)) {
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

    if (_handleResponseError("addTempTarget", ep, response, err)) {
      return false;
    }

    return true;
  }

  Future<bool> switchProfile(String nsURL, String token, String profileName, int duration, int percent) async {
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
      "eventType": "Profile Switch",
      "profile": profileName,
      "percentage": percent,
      "timeshift": 0,
      "date": dateInMilliseconds,
      "mills": dateInMilliseconds, // NightGuard requires this ¯\_(ツ)_/¯
      "app": "carer",
    };

    if (duration != 0) {
      bodyMap["duration"] = duration; // In minutes
      bodyMap["durationInMilliseconds"] = duration * 60 * 1000; // ms
    }

    final (response, err) = await go(http.post(ep,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Accept": " application/json",
          "Authorization": "bearer $jwt",
        },
        body: jsonEncode(bodyMap)));

    if (_handleResponseError("switchProfile", ep, response, err)) {
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
    if (_handleResponseError("entries", ep, response, err)) {
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
    if (_handleResponseError("treatments", ep, response, err)) {
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response!.body);
  }

  Future<NSTreatments> getProfileSwitches(String nsURL, String token, int count) async {
    if (nsURL == "" || token == "") {
      alog("getProfileSwitches No NS URL or token");
      return NSTreatments.empty();
    }
    var ep = treatmentsProfileSwitch(nsURL, token, count);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError("profileSwitches", ep, response, err)) {
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response!.body);
  }

  Future<NSTreatments> getNotes(String nsURL, String token, int count) async {
    if (nsURL == "" || token == "") {
      alog("getNotes No NS URL or token");
      return NSTreatments.empty();
    }
    var ep = treatmentsNote(nsURL, token, count);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError("notes", ep, response, err)) {
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response!.body);
  }

  Future<(NSProfile?, List<NSProfile>, String)> getCurrentProfiles(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getCurrentProfiles No NS URL");
      return (null, <NSProfile>[], "");
    }
    var ep = currentProfile(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError("currentProfile", ep, response, err)) {
      return (null, <NSProfile>[], "");
    }

    var (currentP, otherProfiles) = NSProfile.fromCurrentJson(response!.body);

    return (currentP, otherProfiles, response.body);
  }

  Future<NSProperties?> getProperties(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getProperties No NS URL");
      return null;
    }
    var ep = propertiesEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError("properties", ep, response, err)) {
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
    if (_handleResponseError("deviceStatus", ep, response, err)) {
      return null;
    }

    return NSDeviceStatus.fromDeviceJson(response!.body);
  }

  void incTotalErorrs() {
    totalErrors.value = totalErrors.peek() + 1;
  }

  bool _handleResponseError(String route, Uri uri, Response? response, Object? err) {
    alog("NSCLIENT($route): FETCHED ${uri.toString()}");

    if (err != null || response == null) {
      incTotalErorrs();
      alog("NSCLIENT($route): NSError: Unknown $err");
      ToastService().showError("NSError", description: "$route: Unknown $err");
      return true;
    }

    String body = response.body;

    if (response.statusCode == 500) {
      alog("NSCLIENT($route): NSError: 500 Server error $body");
      // Not our problem if the server is erroring Will log it though, just because we will see if easily
      return true;
    }

    var (json, parseErr) = tryDecodeJson(response.body);
    if (parseErr != null) {
      incTotalErorrs();
      alog("NSCLIENT($route): NSError: Code ${response.statusCode} Bad JSON with Code $body");

      ToastService().showError("NSError", description: "$route: Code ${response.statusCode} Bad JSON");
      return true;
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      incTotalErorrs();
      alog("NSCLIENT($route) NSError: NON 200 response code ${response.statusCode} $body");

      if (json != null && json is Map) {
        if (json.containsKey("message") && json.containsKey("description")) {
          body = "${json["message"]} - ${json["description"]}";
        } else if (json.containsKey("message")) {
          body = json["message"];
        }
      }

      ToastService().showError("NSError", description: "$route: Code (${response.statusCode}) $body");
      return true;
    }

    lastFetched.value = clock.now();
    return false;
  }
}
