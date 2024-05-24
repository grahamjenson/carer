import 'package:carer/models/constants.dart';
import 'package:carer/sql/carer_db.dart';

class SGVs {
  final List<SGV> sgvs;

  const SGVs({
    required this.sgvs,
  });

  static Future<SGV?> lastSGV() async {
    var db = await CarerDB.instance;
    var rawSGV = (await db.sgvs(limit: 1)).firstOrNull;
    if (rawSGV == null) {
      return null;
    }
    return SGV.fromMap(rawSGV);
  }

  // return the last sgvs for minutes
  static Future<SGVs> lastMins(int minsAgo) async {
    var db = await CarerDB.instance;

    // sorted by age
    // grouped into 1 min intervals (select latest/lowest one)
    // reference previous sgv
    var rawSGVs = await db.sgvs(
        after: DateTime.now()
            .subtract(Duration(minutes: minsAgo))
            .millisecondsSinceEpoch);
    List<SGV> ret = [];
    for (var rsvg in rawSGVs) {
      ret.add(SGV.fromMap(rsvg));
    }

    return SGVs(sgvs: ret);
  }

  static Future<double> percentInRangeToday(int low, int high) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    int startOfDayEpoch = startOfDay.millisecondsSinceEpoch;

    var db = await CarerDB.instance;
    var sgvsTodayInRange =
        await db.countSGVs(after: startOfDayEpoch, low: low, high: high);

    var sgvsToday = await db.countSGVs(after: startOfDayEpoch);

    if (sgvsTodayInRange == null || sgvsToday == null || sgvsToday == 0) {
      return 0.0;
    }

    return sgvsTodayInRange / sgvsToday;
  }

  static Future<int> createOrUpdateSGVs(List<SGV> sgvs) async {
    var db = await CarerDB.instance;
    var rawSGVs = sgvs.map((e) {
      return {
        "value": e.value,
        "date": e.date.millisecondsSinceEpoch,
      };
    }).toList();
    return db.batchCreateOrUpdateSGVs(rawSGVs);
  }
}

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
      date: DateTime.fromMillisecondsSinceEpoch(map["date"]),
    );
  }

  Duration get age {
    return DateTime.now().difference(date);
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
}
