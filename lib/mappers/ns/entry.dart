import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/nsclient/entries.dart';

class NSEntryToSGV extends DataMapper<NSEntry, SGV> {
  const NSEntryToSGV();

  @override
  SGV aToB(NSEntry model) {
    return SGV(value: model.sgv, date: model.date, eid: model.id);
  }

  @override
  NSEntry bToA(SGV model) {
    throw UnimplementedError();
  }
}
