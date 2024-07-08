import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;

void main() async {
  print("HERE");
  // get the TOKEN from the environment
  var token = Platform.environment['TOKEN'];
  print("TOKEN: $token");

  var nsURL = Platform.environment['NSURL'];
  print("NSURL: $nsURL");

  var treatmens = await NSClient().getTreatments(nsURL!, token!, 10);
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  var decode = jsonDecode(treatmens.body);
  print(encoder.convert(decode));
  print((decode as List).length);
}

Uri treatmentsEndpoint(nsURL, token, DateTime gteCreatedAt) {
  return Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[created_at][\$gte]=${toNSDateString(gteCreatedAt)}&count=1000');

  //return Uri.parse('$nsURL/api/v1/treatments.json?token=$token&find[created_at][\$gte]=$ms');
}

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

// Singleton
class NSClient {
  Future<http.Response> getTreatments(String nsURL, String token, int count) async {
    var ep = treatmentsEndpoint(nsURL, token, clock.daysAgo(3));
    print(ep);
    final response = await http.get(ep);
    return response;
  }
}
