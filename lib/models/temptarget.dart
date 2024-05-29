import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';

class TempTarget {
  final DateTime startDate;
  final int duration;
  final int targetTop;
  final int targetBottom;

  TempTarget({
    required this.startDate,
    required this.duration,
    required this.targetTop,
    required this.targetBottom,
  });

  DateTime get dateEnd {
    return startDate.add(Duration(seconds: duration));
  }

  Duration get remaining {
    return dateEnd.difference(clock.now());
  }

  factory TempTarget.fromMap(Map<String, dynamic> map) {
    return TempTarget(
      startDate: DateTime.fromMillisecondsSinceEpoch(map["start"]),
      duration: map["duration"],
      targetTop: map["targetTop"],
      targetBottom: map["targetBottom"],
    );
  }

  static Future<int> createOrUpdate(List<TempTarget> models) async {
    var db = await CarerDB.instance;
    var rawModels = models.map((e) {
      return {
        "start": e.startDate.millisecondsSinceEpoch,
        "duration": e.duration,
        "targetTop": e.targetTop,
        "targetBottom": e.targetBottom,
      };
    }).toList();
    return db.batchCreateOrUpdateTempTargets(rawModels);
  }
}
