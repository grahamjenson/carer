import 'package:carer/models/sql/db_model.dart';

enum BolusType {
  correction,
  meal,
  smb;

  static BolusType fromName(String type) {
    for (var t in BolusType.values) {
      if (t.name == type) {
        return t;
      }
    }
    throw ArgumentError("Invalid Bolus Type: $type");
  }
}

class Bolus extends DBModel {
  final double value;
  @override
  final DateTime date;

  BolusType type;
  Bolus({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
    required this.type,
  });

  @override
  String toString() {
    return 'Bolus{value: $value, date: $date, type: $type}';
  }
}
