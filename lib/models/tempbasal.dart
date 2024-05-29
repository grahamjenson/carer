import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';

class TempBasal {
  final DateTime startDate;
  final int duration;
  final double value;

  TempBasal({
    required this.startDate,
    required this.duration,
    required this.value,
  });

  DateTime get dateEnd {
    return startDate.add(Duration(seconds: duration));
  }

  Duration get remaining {
    return dateEnd.difference(clock.now());
  }

  factory TempBasal.fromMap(Map<String, dynamic> map) {
    return TempBasal(
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"]),
      duration: map["duration"],
      value: map["value"],
    );
  }

  static Future<int> createOrUpdate(List<TempBasal> models) async {
    var db = await CarerDB.instance;
    var rawModels = models.map((e) {
      return {
        "start": e.startDate.millisecondsSinceEpoch,
        "duration": e.duration,
        "value": e.value,
      };
    }).toList();
    return db.batchCreateOrUpdateTempBasals(rawModels);
  }
}
