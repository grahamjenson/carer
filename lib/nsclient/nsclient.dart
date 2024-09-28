import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/properties.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
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

Uri entryEndpoint(nsURL, token, DateTime gteCreatedAt) =>
    Uri.parse('$nsURL/api/v1/entries.json?token=$token&find[created_at][\$gte]=${toNSDateString(gteCreatedAt)}&count=1000');

Uri treatmentsEndpoint(nsURL, token, DateTime gteCreatedAt) =>
    Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[created_at][\$gte]=${toNSDateString(gteCreatedAt)}&count=1000');

Uri treatmentsProfileSwitch(nsURL, token, int count) =>
    Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[eventType]=Profile+Switch&count=$count');
Uri treatmentsNote(nsURL, token, int count) => Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[eventType]=Note&count=$count');

Uri summaryEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/summary.json?token=$token');

Uri currentProfile(nsURL, token) => Uri.parse('$nsURL/api/v1/profile/current.json?token=$token');

Uri propertiesEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties.json?token=$token');

// Singleton
class NSClient {
  static final NSClient _singleton = NSClient._internal();
  factory NSClient() => _singleton;
  NSClient._internal();

  ASignal<DateTime?> lastError = ASignal<DateTime?>(null, debugLabel: "NSClientLastError");
  ASignal<DateTime?> lastFetched = ASignal<DateTime?>(null, debugLabel: "NSClientLastCalled");

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

  Future<Summary?> getSummary(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getSummary No NS URL");
      return null;
    }
    var ep = summaryEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (_handleResponseError(ep, response, err)) {
      return null;
    }
    return Summary.fromJson(response!.body);
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

  bool _handleResponseError(Uri uri, Response? response, Object? err) {
    if (err != null || response == null) {
      lastError.value = clock.now();
      return true;
    }
    alog("FETCHED ${uri.toString()}");
    if (response.statusCode != 200) {
      lastError.value = clock.now();
      alog("NON 200 responce code ${response.statusCode}");
      return true;
    }
    lastFetched.value = clock.now();
    return false;
  }
}
