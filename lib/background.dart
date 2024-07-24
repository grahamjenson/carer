import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("BACKGROUND 1");
      // final SharedPreferences prefs = await SharedPreferences.getInstance();
      // print("BACKGROUND 1.1");
      // var dbpath = prefs.getString('dbpath');
      // print("BACKGROUND 1.2 $dbpath");
      // var dbversion = prefs.getInt('dbversion');
      // print("BACKGROUND 1.3 $dbversion");

      // var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
      // print("BACKGROUND 1: $nsURL $dbpath $dbversion");
      // var ep = entryEndpoint(nsURL, nsToken, clock.daysAgo(10));
      // print("BACKGROUND 2, $ep");
      // final response = await http.get(Uri.parse("https://google.com"));
      // print("BACKGROUND 3 ${response.body}");
      // // var entries = NSEntries.fromJson(response.body);
      // // print("BACKGROUND 4: ${entries.entries} entries");
      // var db = await openDatabaseAndCreateTables(dbpath!, dbversion!);
      // print("BACKGROUND 5: $db");
      // var ret = await CarerDB.writeLogToDB(db, clock.now(), "BACKGROUND: Got $response entries from Nightscout", 1);
      // print("BACKGROUND 6: write $ret");
      return Future.value(true);
    } catch (e, st) {
      print("BACKGROUND 7: $e, $st");
      return Future.value(true);
    }
  });
}

Future<Database> openDatabaseAndCreateTables(String dbpath, int dbversion) async {
  // This will grab all the db code and hash it, if it changes it drops all past stuff and replaces
  var db = await openDatabase(
    dbpath,
    version: dbversion,
  );

  return db;
}
