import 'package:carer/models/model.dart';

class Bolus extends Model {
  @override
  ModelRepository get repository => throw UnimplementedError();

  final double value;
  @override
  final DateTime date;

  Bolus({
    super.id,
    required super.eid,
    required this.value,
    required this.date,
  });
}
