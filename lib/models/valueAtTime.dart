import 'package:carer/mappers/sql/profile.dart';
import 'package:carer/mappers/sql/tempbasal.dart';
import 'package:carer/mappers/sql/temptarget.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/db_model.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

class ValueAtTime with DateMixin {
  @override
  final DateTime date;

  final int lowTarget;
  final int highTarget;

  final double basal;
  final int isf;
  final int cr;

  final String profileName;
  final int profilePercent;

  final bool isTempBasal;
  final DateTime? tempBasalEndDate;
  Duration get tempBasalRemaining => tempBasalEndDate?.difference(clock.now()) ?? Duration.zero;

  final bool isTempTarget;
  final DateTime? tempTargetEndDate;
  Duration get tempTargetRemaining => tempTargetEndDate?.difference(clock.now()) ?? Duration.zero;

  final bool isTempProfile;
  final DateTime? tempProfileEndDate;
  Duration get tempProfileRemaining => tempProfileEndDate?.difference(clock.now()) ?? Duration.zero;

  ValueAtTime({
    required this.date,
    required this.lowTarget,
    required this.highTarget,
    required this.basal,
    required this.isf,
    required this.cr,
    required this.profileName,
    required this.profilePercent,
    required this.isTempBasal,
    required this.tempBasalEndDate,
    required this.isTempTarget,
    required this.tempTargetEndDate,
    required this.isTempProfile,
    required this.tempProfileEndDate,
  });

  @override
  String toString() {
    return "ValueAtTime($date, $lowTarget, $highTarget, $basal, $isf, $cr, $profileName, $profilePercent, $isTempBasal, $isTempTarget, $isTempProfile)";
  }

  static ValueAtTime createValueAtTime(
      List<Profile> profiles, List<Profile> profileSwitches, List<TempTarget> tempTargets, List<TempBasal> tempBasals, DateTime date) {
    int hourOfDay = date.hour;

    // make date rounded to nearest minute
    fon(DateRangeDBModel element) => element.isAtTime(date);

    Profile? profile = Profile.selectProfileAtTime(date, profiles, profileSwitches);

    TempBasal? tempBasal = tempBasals.firstWhereOrNull(fon);
    TempTarget? tempTarget = tempTargets.firstWhereOrNull(fon);

    int lowTarget = tempTarget?.lowTarget ?? profile?.lowTarget[hourOfDay] ?? 0;
    int highTarget = tempTarget?.highTarget ?? profile?.highTarget[hourOfDay] ?? 0;

    double basal = tempBasal?.value ?? profile?.basal[hourOfDay] ?? 0;
    int isf = profile?.sens[hourOfDay] ?? 0;
    int cr = profile?.carbratio[hourOfDay] ?? 0;
    String profileName = profile?.name ?? "";
    int profilePercent = profile?.percent ?? 100;

    bool isTempBasal = false;
    DateTime? tempBasalEndDate;
    bool isTempProfile = false;
    DateTime? tempProfileEndDate;
    bool isTempTarget = false;
    DateTime? tempTargetEndDate;

    if (tempBasal != null) {
      isTempBasal = true;
      tempBasalEndDate = tempBasal.endDate;
    }

    if (profile != null && profile.isTempProfile) {
      isTempProfile = true;
      tempProfileEndDate = profile.endDate;
    }

    if (tempTarget != null) {
      isTempTarget = true;
      tempTargetEndDate = tempTarget.endDate;
    }

    ValueAtTime v = ValueAtTime(
      date: date,
      lowTarget: lowTarget,
      highTarget: highTarget,
      basal: basal,
      isf: isf,
      cr: cr,
      profileName: profileName,
      profilePercent: profilePercent,
      isTempBasal: isTempBasal,
      tempBasalEndDate: tempBasalEndDate,
      isTempTarget: isTempTarget,
      tempTargetEndDate: tempTargetEndDate,
      isTempProfile: isTempProfile,
      tempProfileEndDate: tempProfileEndDate,
    );

    return v;
  }

  static ASignal<List<ValueAtTime>> last2Days = ASignal([], debugLabel: 'valueAtTimeLast2Days');
  static ASignal<List<ValueAtTime>> lastSixHours = ASignal([], debugLabel: 'valueAtTimeLastSixHours');

  static ValueAtTime? last() {
    var values = lastSixHours.value;
    if (values.isEmpty) {
      return null;
    }

    return values.first;
  }

  static Future<List<ValueAtTime>> updateValues(int hoursAgo) async {
    var now = clock.now();
    // rounded to nearest minute
    now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    var start = now.subtract(Duration(hours: hoursAgo));

    var profiles = await Profile.fetchAllDefaultStoreProfiles();
    var profileSwitches = await Profile.fetchProfileSwitches();

    // add the profile switches to the profiles
    var tempTargets = await TempTarget.after(start);
    var tempBasals = await TempBasal.after(start);

    // go over the last 6 hours and for every minute generate a new ValueAtTime
    List<ValueAtTime> vats = [];
    for (var i = 0; i < hoursAgo * 60; i++) {
      var d = now.subtract(Duration(minutes: i));
      vats.add(createValueAtTime(profiles, profileSwitches, tempTargets, tempBasals, d));
    }

    return vats;
  }

  static Future<void> setupSQLSignals() async {
    var dependencies = [TimerService().minuteSignal, SQLToProfile().writeSignal, SQLToTempBasal().writeSignal, SQLToTempTarget().writeSignal];
    await signalAssign(lastSixHours, () async => await updateValues(6), debugLabel: 'fetchValueAtTimeLastSixHours', dependencies: dependencies);
    await signalAssign(last2Days, () async => await updateValues(48), debugLabel: 'fetchValueAtTimeLast2Days', dependencies: dependencies);
  }
}
