import 'package:carer/nsclient/nsclient.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() async {
  agroup("shouldRefreshJWT", () {
    // A JWT for this URL and token, expiring at expire
    NSClient clientWithJWT(DateTime expire) {
      var client = NSClient();
      client.jwt = "jwt";
      client.jwtURL = "https://site.example";
      client.jwtToken = "token";
      client.jwtExpire = expire;
      return client;
    }

    atest("refreshes a JWT that expired a minute ago", () async {
      var client = clientWithJWT(clock.minutesAgo(1));
      expect(await client.shouldRefreshJWT("https://site.example", "token"), true);
    });

    atest("refreshes a JWT that expired 10 minutes ago, as Nighttroop's last 60 minutes", () async {
      var client = clientWithJWT(clock.minutesAgo(10));
      expect(await client.shouldRefreshJWT("https://site.example", "token"), true);
    });

    atest("refreshes a JWT that expires now", () async {
      var client = clientWithJWT(clock.now());
      expect(await client.shouldRefreshJWT("https://site.example", "token"), true);
    });

    atest("keeps a JWT that has not expired", () async {
      var client = clientWithJWT(clock.minutesFromNow(30));
      expect(await client.shouldRefreshJWT("https://site.example", "token"), false);
    });

    atest("refreshes for another URL or token, or with no JWT", () async {
      var client = clientWithJWT(clock.minutesFromNow(30));
      expect(await client.shouldRefreshJWT("https://other.example", "token"), true);
      expect(await client.shouldRefreshJWT("https://site.example", "other"), true);
      client.jwt = null;
      expect(await client.shouldRefreshJWT("https://site.example", "token"), true);
    });
  });
}
