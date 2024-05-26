import 'package:carer/models/constants.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';

class SGV {
  final int value;
  final DateTime date;
  SGV? previousSGV;

  SGV({
    required this.value,
    required this.date,
  });

  factory SGV.fromMap(Map<String, dynamic> map) {
    return SGV(
      value: map["value"],
      date: DateTime.fromMillisecondsSinceEpoch(map["timestamp"]),
    );
  }

  Duration get age {
    return clock.now().difference(date);
  }

  double sgvU(Unit unit) {
    return unit.val(value);
  }

  String diffUWithSign(Unit unit) {
    var sgv = unit.val(diffPer5Mins);
    var sgvStr = sgv.toStringAsFixed(1);
    if (sgv == 0) {
      sgvStr = "+0";
    } else if (sgv > 0) {
      sgvStr = "+${sgv.toStringAsFixed(1)}";
    }
    return sgvStr;
  }

  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return value.toString();
      case Unit.mmol:
        return (value / MGtoMMOL).toStringAsFixed(1);
    }
  }

  int get _diff {
    if (previousSGV == null) {
      return 0;
    }
    return value - previousSGV!.value;
  }

  // // also sanity check the last two sgvs
  // // second most recent sgv should be within 5 minutes of most recent
  // var last = sgvs.last;
  // var secondLast = sgvs[sgvs.length - 2];

  // if ((secondLast.age.inMinutes - last.age.inMinutes).abs() > 6) {
  //   return null;
  // }

  int get diffMinutes {
    if (previousSGV == null) {
      return 5;
    }
    return ((previousSGV!.age.inSeconds - age.inSeconds) / 60).round();
  }

  int get diffPer5Mins {
    if (diffMinutes == 0) {
      return 0; // TODO
    }
    return (_diff / diffMinutes * 5).round();
  }

  @override
  String toString() {
    return "SGV: $value@${date.hour}:${date.minute}";
  }

  // STATIC FUNCTIONS
  static Future<SGV?> lastSGV() async {
    var db = await CarerDB.instance;
    var rawSGV = (await db.sgvs(limit: 1)).firstOrNull;
    if (rawSGV == null) {
      return null;
    }
    return SGV.fromMap(rawSGV);
  }

  // return the last sgvs for minutes
  static Future<List<SGV>> lastMins(int minsAgo) async {
    var db = await CarerDB.instance;

    // sorted by age
    // grouped into 1 min intervals (select latest/lowest one)
    // reference previous sgv
    var rawSGVs = await db.sgvs(
        after: clock
            .now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch);
    List<SGV> ret = [];
    for (var rsvg in rawSGVs) {
      ret.add(SGV.fromMap(rsvg));
    }

    return ret;
  }

  static Future<double> percentInRangeToday(int low, int high) async {
    var db = await CarerDB.instance;
    DateTime now = clock.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfDayEpoch = startOfDay.millisecondsSinceEpoch;

    var sgvsTodayInRange =
        await db.countSGVs(after: startOfDayEpoch, low: low, high: high);

    var sgvsToday = await db.countSGVs(after: startOfDayEpoch);

    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  static Future<int> createOrUpdate(List<SGV> models) async {
    var db = await CarerDB.instance;
    var rawModels = models.map((e) {
      return {
        "value": e.value,
        "timestamp": e.date.millisecondsSinceEpoch,
      };
    }).toList();
    return db.batchCreateOrUpdateSGVs(rawModels);
  }
}
