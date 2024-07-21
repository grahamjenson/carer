import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/bolus.dart';
import 'package:carer/models/carbs.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/tempbasal.dart';
import 'package:carer/models/temptarget.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/shared.dart';
import 'package:carer/nsclient/treatments.dart';

class NSBolusToBolus extends DataMapper<NSTreatmentInsulin, Bolus> {
  const NSBolusToBolus();

  @override
  Bolus from(NSTreatmentInsulin model) {
    return Bolus(
      value: model.insulin,
      date: model.date,
      eid: model.id,
    );
  }
}

class NSCarbstoCarbs extends DataMapper<NSTreatmentCarbs, Carbs> {
  const NSCarbstoCarbs();

  @override
  Carbs from(NSTreatmentCarbs model) {
    return Carbs(
      value: model.carbs.round(),
      date: model.date,
      eid: model.id,
    );
  }
}

class NSTempBasalToTempBasal extends DataMapper<NSTreatmentTempBasal, TempBasal> {
  const NSTempBasalToTempBasal();

  @override
  TempBasal from(NSTreatmentTempBasal model) {
    return TempBasal(
      startDate: model.date,
      duration: model.durationInMilliseconds ~/ 1000,
      value: model.absolute,
      eid: model.id,
    );
  }
}

class NSTempTargettoTempTarget extends DataMapper<NSTemporaryTarget, TempTarget> {
  const NSTempTargettoTempTarget();

  @override
  TempTarget from(NSTemporaryTarget model) {
    return TempTarget(
      eid: model.id,
      startDate: model.date,
      duration: model.durationInMilliseconds ~/ 1000,
      highTarget: model.targetTop.toInt(),
      lowTarget: model.targetBottom.toInt(),
    );
  }
}

class NSProfileToProfileExtras {
  final String source;
  final int percent;
  final int duration;

  const NSProfileToProfileExtras(this.source, this.percent, this.duration);
}

class NSProfileToProfile extends DataMapper<(NSProfile, NSProfileToProfileExtras), Profile> {
  const NSProfileToProfile();

  @override
  Profile from((NSProfile, NSProfileToProfileExtras) joint) {
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
}

class NSEntryToSGV extends DataMapper<NSEntry, SGV> {
  const NSEntryToSGV();

  @override
  SGV from(NSEntry model) {
    return SGV(value: model.sgv!, date: model.date, eid: model.id);
  }
}
