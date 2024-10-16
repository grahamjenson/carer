import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/widgets.dart';
import 'package:unicons/unicons.dart';

abstract class _StatMethods {
  const _StatMethods();
  IconData get icon;
  String get title;
  String get description;
  Unit get unit => UISettings().unit;
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small);
}

enum Stat {
  iob(_IOB()),
  cob(_COB()),
  basal(_Basal()),
  target(_Target()),
  currentProfile(_CurrentProfile()),
  todaysInRange(_TodayInRange()),
  yesterdayInRange(_YesterdayInRange());

  final _StatMethods _methods;

  const Stat(this._methods);

  IconData get icon => _methods.icon;
  String get title => _methods.title;
  String get description => _methods.description;
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) =>
      _methods.status(context, style, small);
}

class _IOB extends _StatMethods {
  const _IOB();

  double get value => PropertiesData().iob;

  @override
  String get title => "IOB";

  @override
  String get description => "Insulin on board";

  @override
  IconData get icon => UniconsLine.syringe;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return (["${toMax2dp(value)}", "u"], [style, small]);
  }
}

class _COB extends _StatMethods {
  const _COB();

  double get value => PropertiesData().cob;

  @override
  String get title => "COB";

  @override
  String get description => "Carbs on board";

  @override
  IconData get icon => UniconsLine.restaurant;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return (["${value.round()}", "g"], [style, small]);
  }
}

class _Basal extends _StatMethods {
  const _Basal();

  double get value {
    var valueAtTime = ValueAtTime.last();

    if (valueAtTime != null) {
      return valueAtTime.basal;
    }
    return 0;
  }

  @override
  String get title => "Basal";

  @override
  String get description => "Current Basal Rate";

  @override
  IconData get icon => UniconsLine.tear;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return (["${toMax2dp(value)}", "u/h"], [style, small]);
  }
}

class _Target extends _StatMethods {
  const _Target();

  (int, int) get value {
    var valueAtTime = ValueAtTime.last();

    if (valueAtTime != null) {
      return (valueAtTime.lowTarget, valueAtTime.highTarget);
    }
    return (0, 0);
  }

  @override
  String get title => "Target";

  @override
  String get description => "Current Target Range";

  @override
  IconData get icon => UniconsLine.focus_target;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return (["${value.$1}", "-", "${value.$2}", unit.name], [style, small, style, small]);
  }
}

class _CurrentProfile extends _StatMethods {
  const _CurrentProfile();

  int get value {
    var profile = Profile.currentProfile.value;
    if (profile == null) {
      return -1;
    }

    return profile.percent;
  }

  Duration? get remaining {
    var profile = Profile.currentProfile.value;
    if (profile == null) {
      return null;
    }

    if (profile.duration == 0) {
      return null;
    }

    return profile.remaining;
  }

  @override
  String get title => "Profile";

  @override
  String get description => "Current Profile";

  @override
  IconData get icon => UniconsLine.user;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return (["$value"], [style]);
  }
}

class _TodayInRange extends _StatMethods {
  const _TodayInRange();

  double get value => CleanSGV.todaysPercentage.value ?? 0.0;

  @override
  String get title => "TIR";

  @override
  String get description => "Today's Time in Range";

  @override
  IconData get icon => UniconsLine.chart_pie;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return ([(value.toStringAsFixed(0)), "%"], [style, small]);
  }
}

class _YesterdayInRange extends _StatMethods {
  const _YesterdayInRange();

  double get value => CleanSGV.yesterdaysPercentage.value ?? 0.0;

  @override
  String get title => "YIR";

  @override
  String get description => "Yesterday's Time in Range";

  @override
  IconData get icon => UniconsLine.chart_pie;

  @override
  (List<String> texts, List<TextStyle> styles) status(BuildContext context, TextStyle style, TextStyle small) {
    return ([value.toStringAsFixed(0), "%"], [style, small]);
  }
}
