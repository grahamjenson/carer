import 'package:carer/models/constants.dart';
import 'package:carer/sql/carer_db.dart';
import 'package:clock/clock.dart';

class SGV {
  final int? id;
  final int value;
  final DateTime date;
  int? _diffPer5MinsCache;

  SGV({
    required this.value,
    required this.date,
    this.id,
  });

  factory SGV.fromMap(Map<String, dynamic> map) {
    return SGV(
      id: map["id"],
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

  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return value.toString();
      case Unit.mmol:
        return (value / MGtoMMOL).toStringAsFixed(1);
    }
  }

  Future<int> get diffPer5Mins async {
    if (_diffPer5MinsCache != null) {
      return _diffPer5MinsCache!;
    }

    if (id == null) {
      return 0;
    }

    var db = await CarerDB.instance;
    var rawSGV = await db.sgvWithDiffs(id!);
    if (rawSGV == null) {
      return 0;
    }
    var rate = rawSGV["rate5m"];
    if (rate == null) {
      return 0;
    }

    _diffPer5MinsCache = rawSGV["rate5m"]! as int;
    return _diffPer5MinsCache!;
  }

  Future<String> diffUWithSign(Unit unit) async {
    var sgv = unit.val(await diffPer5Mins);
    var sgvStr = sgv.toStringAsFixed(1);
    if (sgv == 0) {
      sgvStr = "+0";
    } else if (sgv > 0) {
      sgvStr = "+${sgv.toStringAsFixed(1)}";
    }
    return sgvStr;
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
    var sgv = SGV.fromMap(rawSGV);

    return sgv;
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
