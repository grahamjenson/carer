import 'package:carer/mappers/sql_mappers.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/db_model.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/sql/tempbasal.dart';
import 'package:carer/models/sql/temptarget.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';
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
  final bool isTempTarget;
  final bool isTempProfile;

  ValueAtTime({
    required this.date,
    required this.lowTarget,
    required this.highTarget,
    required this.isTempTarget,
    required this.basal,
    required this.isTempBasal,
    required this.isf,
    required this.cr,
    required this.profileName,
    required this.profilePercent,
    required this.isTempProfile,
  });

  @override
  String toString() {
    return "ValueAtTime($date, $lowTarget, $highTarget, $basal, $isf, $cr, $profileName, $profilePercent, $isTempBasal, $isTempTarget, $isTempProfile)";
  }

  static ValueAtTime createValueAtTime(List<Profile> profiles, List<TempTarget> tempTargets, List<TempBasal> tempBasals, DateTime date) {
    int hourOfDay = date.hour;

    // make date rounded to nearest minute
    fon(DateRangeDBModel element) => element.isAtTime(date);

    Profile? profile = profiles.firstWhereOrNull(fon);
    TempBasal? tempBasal = tempBasals.firstWhereOrNull(fon);
    TempTarget? tempTarget = tempTargets.firstWhereOrNull(fon);

    int lowTarget = tempTarget?.lowTarget ?? profile?.lowTarget[hourOfDay] ?? 0;
    int highTarget = tempTarget?.highTarget ?? profile?.highTarget[hourOfDay] ?? 0;

    double basal = tempBasal?.value ?? profile?.basal[hourOfDay] ?? 0;
    int isf = profile?.sens[hourOfDay] ?? 0;
    int cr = profile?.carbratio[hourOfDay] ?? 0;
    String profileName = profile?.name ?? "";
    int profilePercent = profile?.percent ?? 100;

    bool isTempProfile = profile?.isTempProfile ?? false;
    bool isTempBasal = tempBasal != null;
    bool isTempTarget = tempTarget != null;

    ValueAtTime v = ValueAtTime(
      date: date,
      lowTarget: lowTarget,
      highTarget: highTarget,
      isTempTarget: isTempTarget,
      basal: basal,
      isTempBasal: isTempBasal,
      isf: isf,
      cr: cr,
      profileName: profileName,
      profilePercent: profilePercent,
      isTempProfile: isTempProfile,
    );

    return v;
  }

  static ASignal<List<ValueAtTime>> last2Days = ASignal([], debugLabel: 'valueAtTimeLast2Days');
  static ASignal<List<ValueAtTime>> lastSixHours = ASignal([], debugLabel: 'valueAtTimeLastSixHours');

  static Future<List<ValueAtTime>> updateValues(int hoursAgo) async {
    alog('ValueAtTime.updateValues');
    var now = clock.now();
    // rounded to nearest minute
    now = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    var start = now.subtract(Duration(hours: hoursAgo));

    var profiles = await Profile.after(start);
    var tempTargets = await TempTarget.after(start);
    var tempBasals = await TempBasal.after(start);

    // go over the last 6 hours and for every minute generate a new ValueAtTime
    List<ValueAtTime> vats = [];
    for (var i = 0; i < hoursAgo * 60; i++) {
      var d = now.subtract(Duration(minutes: i));
      vats.add(createValueAtTime(profiles, tempTargets, tempBasals, d));
    }

    return vats;
  }

  static setupSQLSignals() {
    var dependencies = [TimerService().minuteSignal, SQLToProfile().writeSignal, SQLToTempBasal().writeSignal, SQLToTempTarget().writeSignal];
    signalAssign(lastSixHours, () async => await updateValues(6), debugLabel: 'valueAtTimeLastSixHours', dependencies: dependencies);
    signalAssign(last2Days, () async => await updateValues(48), debugLabel: 'valueAtTimeLast2Days', dependencies: dependencies);
  }
}
