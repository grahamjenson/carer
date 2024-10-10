import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/nsclient/treatments.dart';

class NSTempTargettoTempTarget extends DataMapper<NSTemporaryTarget, TempTarget> {
  const NSTempTargettoTempTarget();

  @override
  TempTarget aToB(NSTemporaryTarget model) {
    return TempTarget(
      eid: model.id,
      startDate: model.date,
      duration: model.durationInMilliseconds ~/ 1000,
      highTarget: model.targetTop.toInt(),
      lowTarget: model.targetBottom.toInt(),
    );
  }

  @override
  NSTemporaryTarget bToA(TempTarget model) {
    throw UnimplementedError();
  }
}
