import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/nsclient/treatments.dart';

class NSTempBasalToTempBasal extends DataMapper<NSTreatmentTempBasal, TempBasal> {
  const NSTempBasalToTempBasal();

  @override
  TempBasal aToB(NSTreatmentTempBasal model) {
    return TempBasal(
      startDate: model.date,
      duration: model.durationInMilliseconds ~/ 1000,
      value: model.absolute,
      eid: model.id,
    );
  }

  @override
  NSTreatmentTempBasal bToA(TempBasal model) {
    throw UnimplementedError();
  }
}
