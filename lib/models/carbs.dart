import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class Carbs {
  final int value;
  final DateTime date;

  Carbs({
    required this.value,
    required this.date,
  });

  factory Carbs.fromMap(Map<String, dynamic> map) {
    return Carbs(
      value: map["value"],
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"]),
    );
  }

  static Future<int> createOrUpdate(List<Carbs> models) async {
    var db = await CarerDB.instance;
    var rawModels = models.map((e) {
      return {
        "value": e.value,
        "timestamp": e.date.millisecondsSinceEpoch,
      };
    }).toList();
    return db.batchCreateOrUpdateCarbs(rawModels);
  }

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}g';
    } else {
      return "";
    }
  }

  static Future<List<Carbs>> lastMins(int minsAgo) async {
    var db = await CarerDB.instance;

    var rawModels = await db.carbs(
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch);
    List<Carbs> ret = [];
    for (var rModel in rawModels) {
      ret.add(Carbs.fromMap(rModel));
    }

    return ret;
  }
}
