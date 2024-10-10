import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/shared.dart';

class NSProfileToProfileExtras {
  final String source;
  final int percent;
  final int duration;

  const NSProfileToProfileExtras(this.source, this.percent, this.duration);
}

class NSProfileToProfile extends DataMapper<(NSProfile, NSProfileToProfileExtras), Profile> {
  const NSProfileToProfile();

  @override
  Profile aToB((NSProfile, NSProfileToProfileExtras) joint) {
    var (profile, extras) = joint;
    return Profile(
      name: profile.name,
      eid: profile.id,
      startDate: profile.date,
      duration: extras.duration,
      source: extras.source,
      percent: extras.percent,
      dia: profile.dia,
      units: profile.units,
      timezone: profile.timezone,
      carbratio: profile.expandedCarbratio(),
      sens: profile.expandedSens(),
      basal: profile.expandedBasal(),
      lowTarget: profile.expandedTargetLow(),
      highTarget: profile.expandedTargetHigh(),
    );
  }

  @override
  (NSProfile, NSProfileToProfileExtras) bToA(Profile model) {
    throw UnimplementedError();
  }
}

class NSEntryToSGV extends DataMapper<NSEntry, SGV> {
  const NSEntryToSGV();

  @override
  SGV aToB(NSEntry model) {
    return SGV(value: model.sgv!, date: model.date, eid: model.id);
  }

  @override
  NSEntry bToA(SGV model) {
    throw UnimplementedError();
  }
}
