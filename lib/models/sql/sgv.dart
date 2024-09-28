import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/sql/db_model.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';

abstract class ASGV {
  int get value;
  DateTime get date;
  Range5 get range;
  bool get isUrgentLow;
  bool get isLow;
  bool get isNormal;
  bool get isHigh;
  bool get isUrgentHigh;

  int get minsAgo;
  Duration get age;
  String sgvStr(Unit unit);
}

class SGV extends DBModel implements ASGV {
  @override
  final int value;

  @override
  final DateTime date;

  SGV({
    required this.value,
    required this.date,
    required super.eid,
    super.id,
  });

  (Range5, double) get rangeProporation => targetRange(value);
  @override
  Range5 get range => rangeProporation.$1;

  @override
  bool get isUrgentLow => range == Range5.veryLow;
  @override
  bool get isLow => range == Range5.low;
  @override
  bool get isNormal => range == Range5.mid;
  @override
  bool get isHigh => range == Range5.high;
  @override
  bool get isUrgentHigh => range == Range5.veryHigh;

  @override
  String sgvStr(Unit unit) {
    switch (unit) {
      case Unit.mg:
        return value.toString();
      case Unit.mmol:
        return (value / MGtoMMOL).toStringAsFixed(1);
    }
  }

  @override
  String toString() {
    return "SGV($value@${date.hour}:${date.minute})";
  }

  static ASignal<List<SGV>> last2Days = ASignal<List<SGV>>([], debugLabel: "SGVLast2Days");

  static setupSQLSignals() {
    signalAssign(last2Days, () async => SQLToSGV().last2Days(), debugLabel: "SGVlast2Days", dependencies: [SQLToSGV().writeSignal]);
  }
}
