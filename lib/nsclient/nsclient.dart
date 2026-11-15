import 'dart:async';
import 'dart:convert';

import 'package:carer/nsclient/device_status.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/last_modified.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/utils/asentry_http_client.dart';
import 'package:carer/utils/carer_http.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
import 'package:clock/clock.dart';
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
Uri jwtEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/authorization/request/token=$token');

////
// Entries
////

Uri entryHistoryEndpoint(nsURL, int gteCreatedAt) => Uri.parse('$nsURL/api/v3/entries?sort\$desc=date&date\$gte=$gteCreatedAt&limit=576');

////
// Treatments
////

Uri treatmentsWriteEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/treatments');

Uri treatmentsHistoryEndpoint(nsURL, int createdAt) => Uri.parse(
      '$nsURL/api/v3/treatments'
      '?sort\$desc=created_at'
      '&created_at\$gte=${DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true).toIso8601String()}'
      '&limit=500',
    );

Uri treatmentsProfileSwitchEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/treatments?sort\$desc=date&eventType\$eq=Profile%20Switch&limit=1');
Uri treatmentsSensorChangeEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/treatments?sort\$desc=date&eventType\$eq=Sensor%20Change&limit=1');
Uri treatmentsInsulinChangeEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/treatments?sort\$desc=date&eventType\$eq=Insulin%20Change&limit=1');

////
// Device Status
////

Uri deviceStatusEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/devicestatus?sort\$desc=date&limit=1');

////
// Profile
////

Uri currentProfileEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/profile?sort\$desc=date&limit=1');

////
// LastModified
////

Uri lastModifiedEndpoint(nsURL) => Uri.parse('$nsURL/api/v3/lastModified');

// The loop is going to become
// 1. Check Last Modified
// 2. Has it changed since the last check
// 3. Fetch from the collections that have changed

// Add Carbs endpoint

// Singleton
class NSClient {
  static final NSClient _singleton = NSClient._internal();
  factory NSClient() => _singleton;
  NSClient._internal() {
    // Initialize the client
    http = ASentryHttpClient(client: CarerHttp.getClient());
  }

  static ASignal<int> totalErrors = ASignal<int>(0, debugLabel: "NSClientTotalErrors");
  static ASignal<DateTime?> lastFetched = ASignal<DateTime?>(null, debugLabel: "NSClientLastCalled");

  String? jwtURL;
  String? jwtToken;
  String? jwt;
  DateTime? jwtExpire;

  late Client http;

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
    print("NSCLIENT: Testing NS URL and Token with endpoint $ep and token $token and URL $nsURL");
    final (response, err) = await go(http.get(ep).timeout(const Duration(seconds: 3)));
    print("NSCLIENT: testNSUrlAndToken response: ${response?.body}, err: $err");
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
    // Bad URL or token
    if (nsURL == "" || token == "") {
      alog("NSCLIENT: JWT No NS URL or token");
      return false;
    }

    var refreshNow = await shouldRefreshJWT(nsURL, token);
    if (!refreshNow) {
      var duration = jwtExpire!.difference(clock.now()).inMinutes;
      alog("NSCLIENT: JWT is still valid for ${duration}m");
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
    if (jwtExpire!.isBefore(clock.ago(hours: 1))) {
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

    var ep = treatmentsWriteEndpoint(nsURL);

    var date = clock.now();
    var dateInMilliseconds = date.millisecondsSinceEpoch;

    Map<String, dynamic> bodyMap = {
      "eventType": "Carb Correction",
      "carbs": carbs,
      "date": dateInMilliseconds,
      "mills": dateInMilliseconds, // NightGuard requires this ¯\_(ツ)_/¯
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

    var ep = treatmentsWriteEndpoint(nsURL);

    var date = clock.now();
    var dateInMilliseconds = date.millisecondsSinceEpoch;

    Map<String, dynamic> bodyMap = {
      "eventType": "Temporary Target",
      "reason": reason,
      "targetBottom": low,
      "targetTop": high,
      'units': "mg/dl",
      "duration": duration, // In minutes
      "durationInMilliseconds": duration * 60 * 1000, // ms
      "date": dateInMilliseconds,
      "mills": dateInMilliseconds, // NightGuard requires this ¯\_(ツ)_/¯
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

    var ep = treatmentsWriteEndpoint(nsURL);

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

  ///////
  // API CALLS
  //////

  Future<NSLastModified?> getLastModified(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return null;
    }
    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return null;
    }

    var ep = lastModifiedEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));
    if (_handleResponseError("lastModified", ep, response, err)) {
      return null;
    }

    return NSLastModified.fromJson(response!.body);
  }

  Future<NSEntries> getEntries(String nsURL, String token, int gteCreateAt) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return NSEntries.empty();
    }
    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return NSEntries.empty();
    }

    var ep = entryHistoryEndpoint(nsURL, gteCreateAt);

    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));
    if (_handleResponseError("entries", ep, response, err)) {
      return NSEntries.empty();
    }

    return NSEntries.fromJson(response!.body);
  }

  Future<NSTreatments> getTreatments(String nsURL, String token, int gteCreateAt) async {
    if (nsURL == "" || token == "") {
      return NSTreatments.empty();
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return NSTreatments.empty();
    }

    var ep = treatmentsHistoryEndpoint(nsURL, gteCreateAt);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));
    if (_handleResponseError("treatments", ep, response, err)) {
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response!.body);
  }

  Future<NSProfileSwitch?> getProfileSwitches(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getProfileSwitche No NS URL or token");
      return null;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return null;
    }

    var ep = treatmentsProfileSwitchEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));

    if (_handleResponseError("profileSwitches", ep, response, err)) {
      return null;
    }
    var treatments = NSTreatments.fromJson(response!.body);
    if (treatments.profileSwitches.isEmpty) {
      return null;
    }

    return treatments.profileSwitches.first;
  }

  Future<NSInsulinChange?> getInsulinChange(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getInsulinChanges No NS URL or token");
      return null;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return null;
    }

    var ep = treatmentsInsulinChangeEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));

    if (_handleResponseError("insulinChanges", ep, response, err)) {
      return null;
    }
    var treatments = NSTreatments.fromJson(response!.body);
    if (treatments.insulinChanges.isEmpty) {
      return null;
    }

    return treatments.insulinChanges.first;
  }

  Future<NSSensorChange?> getSensorChange(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getSensorChanges No NS URL or token");
      return null;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return null;
    }

    var ep = treatmentsSensorChangeEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));

    if (_handleResponseError("sensorChanges", ep, response, err)) {
      return null;
    }
    var treatments = NSTreatments.fromJson(response!.body);
    if (treatments.sensorChanges.isEmpty) {
      return null;
    }

    return treatments.sensorChanges.first;
  }

  Future<(NSProfile?, List<NSProfile>, String)> getCurrentProfiles(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getCurrentProfiles No NS URL");
      return (null, <NSProfile>[], "");
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return (null, <NSProfile>[], "");
    }
    var ep = currentProfileEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));

    if (_handleResponseError("currentProfile", ep, response, err)) {
      return (null, <NSProfile>[], "");
    }

    var (currentP, otherProfiles) = NSProfile.fromCurrentJson(response!.body);

    return (currentP, otherProfiles, response.body);
  }

  Future<NSDeviceStatus?> getDeviceStatus(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getDeviceStatus No NS URL or token");
      return null;
    }

    var jwtSuccess = await refreshJWT(nsURL, token);
    if (!jwtSuccess) {
      return null;
    }

    var ep = deviceStatusEndpoint(nsURL);
    final (response, err) = await go(http.get(ep, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      "Accept": " application/json",
      "Authorization": "bearer $jwt",
    }));
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

    if (response.statusCode == 401) {
      alog("NSCLIENT($route): NSError: 401 Unauthorized $body");
      incTotalErorrs();
      ToastService().showError("NSError", description: "$route: 401 Unauthorized");
      jwtExpire = null;
      return true;
    }

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
