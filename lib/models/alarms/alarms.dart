import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/t1d_cn.dart';
import 'package:carer/utils/math.dart';

abstract class Alarm {
  final Settings settings;
  final T1DCN t1d;

  const Alarm({required this.settings, required this.t1d});

  String get name;
  String get description;

  bool trigger();
  bool active();
}

class UrgentLowAlarm extends Alarm {
  const UrgentLowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Urgent Low Alarm';

  @override
  String get description => 'Triggers when BGL is below the urgent low target';

  @override
  bool trigger() {
    return t1d.targetRange5 == Range5.veryLow;
  }

  @override
  bool active() {
    return settings.alarmSettings.urgentLowAlarm;
  }
}

class LowAlarm extends Alarm {
  const LowAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Low Alarm';

  @override
  String get description => 'Triggers when BGL is below the low target';

  @override
  bool trigger() {
    return t1d.targetRange5 == Range5.low;
  }

  @override
  bool active() {
    return settings.alarmSettings.lowAlarm;
  }
}

class HighAlarm extends Alarm {
  const HighAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'High Alarm';

  @override
  String get description => 'Triggers when BGL is above the high target';

  @override
  bool trigger() {
    return t1d.targetRange5 == Range5.high;
  }

  @override
  bool active() {
    return settings.alarmSettings.highAlarm;
  }
}

class UrgentHighAlarm extends Alarm {
  const UrgentHighAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Urgent High Alarm';

  @override
  String get description => 'Triggers when BGL is above the urgent high target';

  @override
  bool trigger() {
    return t1d.targetRange5 == Range5.veryHigh;
  }

  @override
  bool active() {
    return settings.alarmSettings.urgentHighAlarm;
  }
}

class FastRiseAlarm extends Alarm {
  const FastRiseAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Fast Rise Alarm';

  @override
  String get description => 'Triggers when BGL is rising quickly';

  @override
  bool trigger() {
    return t1d.diffRange7 == Range7.high;
  }

  @override
  bool active() {
    return settings.alarmSettings.fastRiseAlarm;
  }
}

class FastDropAlarm extends Alarm {
  const FastDropAlarm({required super.settings, required super.t1d});

  @override
  String get name => 'Fast Drop Alarm';

  @override
  String get description => 'Triggers when BGL is dropping quickly';

  @override
  bool trigger() {
    return t1d.diffRange7 == Range7.low;
  }

  @override
  bool active() {
    return settings.alarmSettings.fastDropAlarm;
  }
}
