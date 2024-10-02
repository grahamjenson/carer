import 'package:carer/mappers/mapper.dart';
import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/sql/carbs.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/nsclient/entries.dart';
import 'package:carer/nsclient/shared.dart';
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
