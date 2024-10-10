import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/nsclient/treatments.dart';

class NSCarbstoCarbs extends DataMapper<NSTreatmentCarbs, Carbs> {
  const NSCarbstoCarbs();

  @override
  Carbs aToB(NSTreatmentCarbs model) {
    return Carbs(
      value: model.carbs.round(),
      date: model.date,
      eid: model.id,
    );
  }

  @override
  NSTreatmentCarbs bToA(Carbs model) {
    throw UnimplementedError();
  }
}
