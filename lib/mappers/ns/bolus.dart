import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/nsclient/treatments.dart';

class NSBolusToBolus extends DataMapper<NSTreatmentInsulin, Bolus> {
  const NSBolusToBolus();

  @override
  Bolus aToB(NSTreatmentInsulin model) {
    var type = BolusType.meal;
    switch (model.type) {
      case NSTreatmentInsulinType.correction:
        type = BolusType.correction;
        break;
      case NSTreatmentInsulinType.smb:
        type = BolusType.smb;
        break;
      case NSTreatmentInsulinType.meal:
        type = BolusType.meal;
        break;
    }
    return Bolus(
      value: model.insulin,
      date: model.date,
      eid: model.id,
      type: type,
    );
  }

  @override
  NSTreatmentInsulin bToA(Bolus model) {
    throw UnimplementedError();
  }
}
