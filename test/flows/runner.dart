// The UI flows: tests of Carer as a person uses it, in the language of Nighttroop's .bdd tests, which run the same on
// any device (README.md)
import 'dart:convert';

import 'package:carer/main.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/ns_collection_update_service.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:carer/sql/key_value_store.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/router.dart' as routes;
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:toastification/toastification.dart';

// How long a step waits for what it looks for
const stepTimeout = Duration(seconds: 15);

typedef Screenshot = Future<void> Function(String name);

// Line is one step of a flow: a line that is not blank or a comment, with each INCLUDEd file's lines in its place
class Line {
  final String path, text, first, rest;
  final int number;
  Line(this.path, this.number, this.text, this.first, this.rest);
}

List<Line> readLines(String path, Map<String, String> files) {
  var contents = files[path];
  if (contents == null) throw TestFailure("No flow file $path");
  var lines = <Line>[];
  var number = 0;
  for (var text in const LineSplitter().convert(contents)) {
    number++;
    text = text.trim();
    if (text.isEmpty || text.startsWith("//") || text.startsWith("#")) continue;
    var space = text.indexOf(" ");
    var first = space < 0 ? text : text.substring(0, space);
    var rest = space < 0 ? "" : text.substring(space + 1).trim();
    lines.addAll(first == "INCLUDE" ? readLines(rest, files) : [Line(path, number, text, first, rest)]);
  }
  return lines;
}

// FakeNightscout is the Nightscout a flow's Carer uses, which keeps what it is sent and records each request
class FakeNightscout {
  final collections = <String, List<Map<String, dynamic>>>{"entries": [], "treatments": []};
  final lastModified = <String, int>{"entries": 0, "treatments": 0};
  final requests = <http.Request>[];

  void add(String collection, Map<String, dynamic> doc) {
    collections[collection]!.add(doc);
    lastModified[collection] = clock.now().millisecondsSinceEpoch;
  }

  MockClient client() => MockClient((request) async {
        requests.add(request);
        var path = request.url.path;
        if (path.startsWith("/api/v2/authorization/request/")) {
          var exp = clock.now().add(const Duration(hours: 8)).millisecondsSinceEpoch ~/ 1000;
          return http.Response(jsonEncode({"token": "flow-jwt", "exp": exp}), 200);
        }
        if (path == "/api/v3/lastModified") {
          return http.Response(
              jsonEncode({
                "result": {"collections": lastModified}
              }),
              200);
        }
        var collection = path.replaceFirst("/api/v3/", "");
        if (request.method == "POST" && collections.containsKey(collection)) {
          add(collection, jsonDecode(request.body));
          return http.Response(jsonEncode({"status": 201, "identifier": "flow-${requests.length}"}), 201);
        }
        return http.Response(jsonEncode({"result": collections[collection] ?? []}), 200);
      });
}

bool _carerSetup = false;

// runFlow runs the flow at path in files, starting Carer with its storage, settings and Nightscout empty
Future<void> runFlow(WidgetTester tester, String path, Map<String, String> files, {Screenshot? screenshot}) async {
  var lines = readLines(path, files);
  var ns = FakeNightscout();
  NSClient().http = ns.client();
  NSClient().jwtExpire = null;
  if (!_carerSetup) await setupCarer();
  _carerSetup = true;
  await (await CarerDB.instance).deleteAll();
  await (await KeyValueStore.instance).deleteAll();
  await SecureSettings().store.deleteAll();
  resetAllSignals();
  routes.router = null;
  for (var collection in NSCollectionUpdateService().collections) {
    collection.lastModifiedMilliSeconds = 0;
  }
  NSCollectionUpdateService().start();
  await tester.pumpWidget(const MyApp());

  try {
    for (var line in lines) {
      try {
        debugPrint("${line.path}:${line.number}: ${line.text}");
        await _step(tester, ns, line, screenshot);
      } on TestFailure catch (e) {
        throw TestFailure("${line.path}:${line.number}: ${line.text}\n${e.message}");
      }
    }
  } finally {
    NSCollectionUpdateService().stop();
    // The toasts' overlay goes once they do, or the next flow's toasts would be put in this flow's app
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  }
}

Future<void> _step(WidgetTester tester, FakeNightscout ns, Line line, Screenshot? screenshot) async {
  switch (line.first) {
    // NIGHTSCOUT_READINGS 120 125 130: Nightscout has these readings in mg/dL, the last now and each 5 minutes before the next
    case "NIGHTSCOUT_READINGS":
      var values = line.rest.split(RegExp(r"\s+")).reversed.toList();
      for (var (i, value) in values.indexed) {
        var date = clock.now().subtract(Duration(minutes: 5 * i)).millisecondsSinceEpoch;
        ns.add("entries", {"identifier": "flow-$date", "type": "sgv", "sgv": int.parse(value), "date": date});
      }
    case "CLICK":
      var found = await _waitFor(tester, _target(line.rest));
      await tester.ensureVisible(found.first);
      await tester.tap(found.first);
      await tester.pump();
    // INPUT #key text: types text into the field
    case "INPUT":
      var space = line.rest.indexOf(" ");
      var found = await _waitFor(tester, _target(line.rest.substring(0, space)));
      await tester.enterText(found.first, line.rest.substring(space + 1));
      await tester.pump();
    case "ASSERT_VISIBLE":
      await _waitFor(tester, _target(line.rest));
    case "ASSERT_TEXT_VISIBLE":
      await _waitFor(tester, find.textContaining(line.rest, findRichText: true));
    case "ASSERT_NOT_VISIBLE":
      await _waitFor(tester, _target(line.rest), gone: true);
    case "ASSERT_PATH":
      String at() => routes.getRouter().routerDelegate.currentConfiguration.uri.path;
      await _waitUntil(tester, () => at() == line.rest, () => "The path is ${at()}");
    // ASSERT_REQUEST POST /api/v3/treatments text: Carer sent Nightscout a request whose body has text
    case "ASSERT_REQUEST":
      var parts = line.rest.split(" ");
      var (method, path, text) = (parts[0], parts[1], parts.skip(2).join(" "));
      bool sent(http.Request r) => r.method == method && r.url.path == path && r.body.contains(text);
      await _waitUntil(tester, () => ns.requests.any(sent), () {
        return "Requests: ${ns.requests.where((r) => r.method != "GET").map((r) => "${r.method} ${r.url.path} ${r.body}")}";
      });
    case "SCREENSHOT":
      await tester.pump();
      await screenshot?.call(line.rest);
    default:
      throw TestFailure("No step ${line.first}");
  }
}

// _target finds #key, a widget with the ValueKey key, or text=text, one with the text
Finder _target(String target) {
  if (target.startsWith("#")) return find.byKey(ValueKey(target.substring(1)));
  if (target.startsWith("text=")) return find.text(target.substring(5), findRichText: true);
  throw TestFailure("$target is not #key or text=text");
}

Future<Finder> _waitFor(WidgetTester tester, Finder finder, {bool gone = false}) async {
  await _waitUntil(tester, () => finder.evaluate().isEmpty == gone, () => "Looked for $finder");
  return finder;
}

Future<void> _waitUntil(WidgetTester tester, bool Function() done, String Function() why) async {
  for (var waited = Duration.zero; waited < stepTimeout; waited += const Duration(milliseconds: 100)) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!done()) throw TestFailure("Not within ${stepTimeout.inSeconds}s. ${why()}");
}
