import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/nsclient/shared.dart';

enum NSProfileSource {
  currentDefault,
  note,
  profileSwitch,
}

class NSProfileToProfileExtras {
  final NSProfileSource source;
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
      source: extras.source.name,
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
