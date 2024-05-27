// Non persisted combined model of Bolus and Carbs
import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class Treatment {
  DateTime date;
  double? insulin;
  int? carbs;
  int count;

  Treatment({required this.date, this.insulin, this.carbs, this.count = 1});

  static Future<List<Treatment>> concatSummary(int minsAgo) async {
    var db = await CarerDB.instance;
    List<Treatment> treatments = [];
    for (var e in (await db.concatedTreatments(
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch))) {
      treatments.add(
        Treatment(
          date: DateTime.fromMillisecondsSinceEpoch(e["max_ts"] as int),
          insulin: e["insulin"] as double?,
          carbs: e["carbs"] as int?,
          count: e["count"] as int,
        ),
      );
    }

    return treatments;
  }

  bool get isConcated => count > 1;

  Duration get age {
    return clock.now().difference(date);
  }

  String get insulinStr {
    if (insulin != null && insulin != 0) {
      return '${toMax2dp(insulin!)}u';
    } else {
      return "";
    }
  }

  String get carbStr {
    if (carbs != null && carbs != 0) {
      return '${toMax2dp(carbs!)}g';
    } else {
      return "";
    }
  }

  // static List<Treatment> summarizedTreatments(int minsAgo, int window) {
  //   List<Treatment> spots = [];
  //   var lastTreatments = lastMins(minsAgo);
  //   var now = clock.now();
  //   // always start the window in the same place to make sure the same treatments are grouped together
  //   var startDate = now.subtract(Duration(minutes: minsAgo));

  //   // This is not 100% efficient because it always scans at least an hour, but this is the easiest for now
  //   var startWindow = DateTime(
  //       startDate.year, startDate.month, startDate.day, startDate.hour, 0);
  //   var endWindow = DateTime(
  //       startDate.year, startDate.month, startDate.day, startDate.hour, window);

  //   // We are going to group all treatments into 5 minute window blocks to make it more readable
  //   while (endWindow.isBefore(now)) {
  //     var treatments = lastTreatments.where((t) =>
  //         (t.date.isAfter(startWindow) || t.date == startWindow) &&
  //         t.date.isBefore(endWindow));

  //     startWindow = endWindow;
  //     endWindow = endWindow.add(Duration(minutes: window));

  //     if (treatments.isEmpty) {
  //       continue;
  //     }

  //     var insulin = treatments
  //         .where((t) => t.insulin != null)
  //         .map((t) => t.insulin!)
  //         .fold(0.0, (a, b) => a + b);
  //     var carbs = treatments
  //         .where((t) => t.carbs != null)
  //         .map((t) => t.carbs!)
  //         .fold(0, (a, b) => a + b);

  //     // the latest date from treatments
  //     var date =
  //         treatments.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;

  //     var newSummary =
  //         SummaryTreatment(insulin: insulin, carbs: carbs, mills: date);

  //     spots.add(newSummary);
  //   }
  //   spots.sort((a, b) => b.date.compareTo(a.date));
  //   return spots;
  // }
}
