import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/nsclient/treatments.dart';

class NSCarbsToCarbs extends DataMapper<NSTreatmentCarbs, Carbs> {
  const NSCarbsToCarbs();

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
