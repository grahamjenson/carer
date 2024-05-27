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
}
