import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/nsclient/treatments.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
import 'package:http/http.dart' as http;

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

Uri summaryEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/summary.json?token=$token');

Uri iobEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/iob.json?token=$token');
Uri cobEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/cob.json?token=$token');
Uri basalEndpoint(nsURL, token) => Uri.parse('$nsURL/api/v2/properties/basal.json?token=$token');

// Singleton
class NSClient {
  Future<NSEntries> getEntries(String nsURL, String token, DateTime gteCreateAt) async {
    if (nsURL == "" || token == "") {
      alog("No NS URL or token");
      return NSEntries.empty();
    }
    var ep = entryEndpoint(nsURL, token, gteCreateAt);
    final (response, err) = await go(http.get(ep));
    if (err != null || response == null) {
      return NSEntries.empty();
    }
    alog("FETCHED ${ep.toString()}");
    if (response.statusCode != 200) {
      alog("NON 200 responce code ${response.statusCode}");
      return NSEntries.empty();
    }

    return NSEntries.fromJson(response.body);
  }

  Future<NSTreatments> getTreatments(String nsURL, String token, DateTime gteCreateAt) async {
    if (nsURL == "" || token == "") {
      return NSTreatments.empty();
    }
    var ep = treatmentsEndpoint(nsURL, token, gteCreateAt);
    final (response, err) = await go(http.get(ep));
    if (err != null || response == null) {
      return NSTreatments.empty();
    }
    alog("FETCHED ${ep.toString()}");
    if (response.statusCode != 200) {
      alog("NON 200 responce code ${response.statusCode}");
      return NSTreatments.empty();
    }

    return NSTreatments.fromJson(response.body);
  }

  Future<Summary?> getSummary(String nsURL, String token) async {
    if (nsURL == "" || token == "") {
      alog("getSummary No NS URL");
      return null;
    }
    var ep = summaryEndpoint(nsURL, token);
    final (response, err) = await go(http.get(ep));
    if (err != null || response == null) {
      return null;
    }
    alog("FETCHED ${ep.toString()}");
    if (response.statusCode != 200) {
      alog("NON 200 responce code ${response.statusCode}");
      return null;
    }
    return Summary.fromJson(response.body);
  }
}

//@GET("api/v1/entries.json")
// suspend fun entries(
//     @Query("find[dateString][\$gte]") date_from: String,
//     @Query("find[dateString][\$lte]") date_to: String,
//     @Query("count") count: Int
// ): Response<List<Entry>>

// @GET("api/v1/treatments.json")
// suspend fun treatments(
//     @Query("find[created_at][\$gte]") date_from: String,
//     @Query("find[created_at][\$lte]") date_to: String,
//     @Query("count") count: Int
// ): Response<List<Treatment>>

// @GET("api/v2/properties/iob.json")
// suspend fun iob(): Response<IOB>

// @GET("api/v2/properties/basal.json")
// suspend fun basal(): Response<Basal>
