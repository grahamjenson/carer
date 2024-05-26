import 'package:carer/sql/carer_db.dart';
import 'package:carer/utils/math.dart';
import 'package:clock/clock.dart';

class Bolus {
  final double value;
  final DateTime date;

  Bolus({
    required this.value,
    required this.date,
  });

  factory Bolus.fromMap(Map<String, dynamic> map) {
    return Bolus(
      value: map["value"].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"]),
    );
  }

  static Future<int> createOrUpdate(List<Bolus> models) async {
    var db = await CarerDB.instance;
    var rawModels = models.map((e) {
      return {
        "value": e.value,
        "timestamp": e.date.millisecondsSinceEpoch,
      };
    }).toList();
    return db.batchCreateOrUpdateBoluses(rawModels);
  }

  String get str {
    if (value != 0) {
      return '${toMax2dp(value)}u';
    } else {
      return "";
    }
  }

  static Future<List<Bolus>> lastMins(int minsAgo) async {
    var db = await CarerDB.instance;

    var rawModels = await db.boluses(
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch);
    List<Bolus> ret = [];
    for (var rModel in rawModels) {
      ret.add(Bolus.fromMap(rModel));
    }

    return ret;
  }
}
