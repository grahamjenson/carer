import 'package:carer/nsclient/entries.dart';
import 'package:carer/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Uri entryEndpoint(nsURL, token) =>
    Uri.parse('$nsURL/api/v1/entries.json?token=$token');
Uri treatmentsEndpoint(nsURL, token) =>
    Uri.parse('$nsURL/api/v1/treatments.json?token=$token');

Uri iobEndpoint(nsURL, token) =>
    Uri.parse('$nsURL/api/v2/properties/iob.json?token=$token');
Uri cobEndpoint(nsURL, token) =>
    Uri.parse('$nsURL/api/v2/properties/cob.json?token=$token');
Uri basalEndpoint(nsURL, token) =>
    Uri.parse('$nsURL/api/v2/properties/basal.json?token=$token');

// Singleton
class NSClient {
  Future<Entries?> getEntries() async {
    try {
      var (nsURL, token) = await Settings.getNightScoutURLToken();
      if (nsURL == "" || token == "") {
        throw Exception("No URL");
      }
      final response = await http.get(entryEndpoint(nsURL, token));

      if (response.statusCode != 200) {
        print("NON 200 responce code ${response.statusCode}");
        throw Exception("Bad HTTP");
      }

      return Entries.fromJson(response.body);
    } catch (e) {
      print(e);
      return Future.value(Entries([]));
    }
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
