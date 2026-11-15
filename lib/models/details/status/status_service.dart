import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/alarm_alert_settings.dart';
import 'package:carer/services/settings/alarm_settings.dart';
import 'package:carer/services/settings/status_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

abstract class _StatusMethods {
  const _StatusMethods();
  IconData get icon;
  String get title;
  String get description;
  String get reason;
  String get status => reason;
  bool triggered();
}

enum Status {
  cannulaChange(_CannulaChange()),
  sensorChange(_SensorChange()),
  thisPhoneNotCharging(_ThisPhoneNotCharging()),
  t1dPhoneNotCharging(_T1DPhoneNotCharging()),
  powerLow(_PowerLow()),
  silentOn(_SilentOn()),
  lowReservoir(_LowReservoir()),
  disabledAlarms(_DisabledAlarms()),
  disabledAudioAlarms(_DisabledAudioAlarms()),
  screenCanSleep(_ScreenCanSleep()),
  ;

  final _StatusMethods _methods;

  const Status(this._methods);

  IconData get icon => _methods.icon;
  String get title => _methods.title;
  String get reason => _methods.reason;
  String get status => _methods.status;
  String get description => _methods.description;
  bool triggered() {
    if (!StatusSettings().statusDisabledContains(name)) {
      return _methods.triggered();
    }
    return false;
  }
}

class _ScreenCanSleep extends _StatusMethods {
  const _ScreenCanSleep();

  @override
  String get title => "Screen Can Sleep";

  @override
  String get description => "If the Screen Sleeps Alarms will not work";

  @override
  IconData get icon => CarerIcons.STATUS_SCREEN_CAN_SLEEP;

  @override
  String get reason {
    return "Screen Not Locked";
  }

  @override
  bool triggered() {
    return !UISettings().screenActive;
  }
}

class _DisabledAudioAlarms extends _StatusMethods {
  const _DisabledAudioAlarms();

  @override
  String get title => "Disabled Audio Alarms";

  @override
  String get description => "Shows When Audio Alarms are Disabled";

  @override
  IconData get icon => CarerIcons.STATUS_DISABLED_AUDIO_ALARMS;

  @override
  String get reason {
    return "Audio Alarms Disabled";
  }

  @override
  bool triggered() {
    return !AlarmAlertSettings().enableAudioAlarm;
  }
}

class _DisabledAlarms extends _StatusMethods {
  const _DisabledAlarms();

  @override
  String get title => "Disabled Alarms";

  @override
  String get description => "Shows When Alarms are Disabled";

  @override
  IconData get icon => CarerIcons.STATUS_DISABLED_ALARMS;

  @override
  String get reason {
    return "Alarms Disabled";
  }

  @override
  bool triggered() {
    return AlarmSettings().disableAlarms;
  }
}

class _CannulaChange extends _StatusMethods {
  const _CannulaChange();

  @override
  String get title => "Cannula Change";

  @override
  String get description => "Shows 24 hours before change";

  @override
  IconData get icon => CarerIcons.STATUS_CANNULA_CHANGE;

  @override
  String get status {
    var cage = PropertiesData().cage;
    if (cage == null) {
      return "Cannula Change Unknown";
    }
    var hours = hoursLeft(cage);
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    var (daysOld, hoursOld) = daysHoursOld(cage);
    return "Cannula (${daysOld}d${hoursOld}h) change $hoursStr";
  }

  @override
  String get reason {
    var cage = PropertiesData().cage;
    if (cage == null) {
      return "Cannula Change Unknown";
    }
    var hours = hoursLeft(cage);
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Cannula Change $hoursStr";
  }

  int hoursLeft(DateTime cage) {
    var cageExpiry = cage.add(StatusSettings().cannulaDuration);
    var hours = cageExpiry.difference(clock.now()).inHours;
    return hours;
  }

  (int, int) daysHoursOld(DateTime cage) {
    var diff = clock.now().difference(cage);
    return (diff.inDays, diff.inHours % 24);
  }

  @override
  bool triggered() {
    var cage = PropertiesData().cage;
    if (cage == null) {
      return true;
    }
    return hoursLeft(cage) < 24;
  }
}

class _SensorChange extends _StatusMethods {
  const _SensorChange();

  @override
  String get title => "Sensor Change";

  @override
  String get description => "Shows 24 hours before change";

  @override
  IconData get icon => CarerIcons.STATUS_SENSOR_CHANGE;

  @override
  String get status {
    var sage = PropertiesData().sage;
    if (sage == null) {
      return "Sensor Change Unknown";
    }
    var hours = hoursLeft(sage);
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    var (daysOld, hoursOld) = daysHoursOld(sage);
    return "Sensor (${daysOld}d${hoursOld}h old) Change $hoursStr";
  }

  @override
  String get reason {
    var sage = PropertiesData().sage;
    if (sage == null) {
      return "Sensor Change Unknown";
    }
    var hours = hoursLeft(sage);
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Sensor Change $hoursStr";
  }

  int hoursLeft(DateTime sage) {
    var sageExpiry = sage.add(StatusSettings().sensorDuration);
    var hours = sageExpiry.difference(clock.now()).inHours;
    return hours;
  }

  (int, int) daysHoursOld(DateTime sage) {
    var diff = clock.now().difference(sage);
    return (diff.inDays, diff.inHours % 24);
  }

  @override
  bool triggered() {
    var sage = PropertiesData().sage;
    if (sage == null) {
      return true;
    }

    return hoursLeft(sage) < 24;
  }
}

class _ThisPhoneNotCharging extends _StatusMethods {
  const _ThisPhoneNotCharging();

  @override
  String get title => "This Phone Not Charging";

  @override
  String get description => "Shows When This Phone is not Charging";

  @override
  IconData get icon => CarerIcons.STATUS_THIS_PHONE_NOT_CHARGING;

  @override
  String get status {
    var thisChargingStr = PlatformInfoService().thisPhoneIsCharging() ? "Charging" : "Not Charging";

    return "Battery(${PlatformInfoService().batteryLevel.value}%) $thisChargingStr";
  }

  @override
  String get reason {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();

    if (!thisPhonesCharging) {
      return "Battery(${PlatformInfoService().batteryLevel.value}%) Not Charging";
    }

    return "";
  }

  @override
  bool triggered() {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();

    return !thisPhonesCharging;
  }
}

class _T1DPhoneNotCharging extends _StatusMethods {
  const _T1DPhoneNotCharging();

  @override
  String get title => "T1D Phone Not Charging";

  @override
  String get description => "Shows When T1D Phone is not Charging";

  @override
  IconData get icon => CarerIcons.STATUS_T1D_PHONE_NOT_CHARGING;

  @override
  String get status {
    return "T1D Phone Battery(${PropertiesData().t1dPhonesBatteryStr}) ${PropertiesData().t1dPhoneChargingStr}";
  }

  @override
  String get reason {
    var t1dPhonesCharging = PropertiesData().t1dPhoneCharging;
    if (t1dPhonesCharging == null || !t1dPhonesCharging) {
      return "T1D Phone Battery(${PropertiesData().t1dPhonesBatteryStr}) Not Charging";
    }
    return "";
  }

  @override
  bool triggered() {
    var t1dPhonesCharging = PropertiesData().t1dPhoneCharging;

    return t1dPhonesCharging == null || !t1dPhonesCharging;
  }
}

class _PowerLow extends _StatusMethods {
  const _PowerLow();

  @override
  String get title => "Power Low";

  @override
  String get description => "Shows When Phone Battery is below 30%";

  @override
  IconData get icon => CarerIcons.STATUS_BATTERY_LOW;

  @override
  String get status {
    List<String> tooltip = [];

    tooltip.add("T1D Phone Battery(${PropertiesData().t1dPhonesBatteryStr})");
    tooltip.add("Battery(${PlatformInfoService().batteryLevel.value}%)");
    return tooltip.join("\n");
  }

  @override
  String get reason {
    List<String> tooltip = [];

    if (thisPhoneLowPower()) {
      var thisPhonesBattery = PlatformInfoService().thisPhonesBatteryLevel();
      tooltip.add("Battery < 30%($thisPhonesBattery%)");
    }

    if (t1dPhoneLowPower()) {
      var t1dPhonesBatteryLevel = PropertiesData().t1dPhonesBatteryStr;
      tooltip.add("T1D Phones Battery < 30%($t1dPhonesBatteryLevel)");
    }

    return tooltip.join("\n");
  }

  bool thisPhoneLowPower() {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var thisPhonesBattery = PlatformInfoService().thisPhonesBatteryLevel();
    return !thisPhonesCharging && thisPhonesBattery < 30;
  }

  bool t1dPhoneLowPower() {
    var t1dPhonesCharging = PropertiesData().t1dPhoneCharging;
    var t1dPhonesBatteryLevel = PropertiesData().t1dPhoneBattery;
    if (t1dPhonesCharging == null || t1dPhonesBatteryLevel == null) {
      return true;
    }
    return !t1dPhonesCharging && t1dPhonesBatteryLevel < 30;
  }

  @override
  bool triggered() {
    if (thisPhoneLowPower()) {
      return true;
    }
    if (t1dPhoneLowPower()) {
      return true;
    }
    return false;
  }
}

class _SilentOn extends _StatusMethods {
  const _SilentOn();

  @override
  String get title => "Silent Mode";

  @override
  String get description => "Shows When Silent Mode is On";

  @override
  IconData get icon => CarerIcons.STATUS_SILENT_MODE;

  @override
  String get reason {
    if (triggered()) {
      return "Silent Mode On";
    }
    return "Silent Mode Off";
  }

  @override
  bool triggered() {
    var ringer = PlatformInfoService().ringerMode.value;
    return (ringer == RingerMode.silent || ringer == RingerMode.vibrate);
  }
}

class _LowReservoir extends _StatusMethods {
  const _LowReservoir();

  @override
  String get title => "Low Reservoir";

  @override
  String get description => "Shows When Reservoir below 20u";

  @override
  IconData get icon => CarerIcons.STATUS_LOW_RESERVOIR;

  @override
  String get reason {
    var reservoir = PropertiesData().reservoir;
    if (reservoir == null) {
      return "Reservoir Unknown";
    }
    return "Reservoir has ${reservoir.toInt()}u remaining";
  }

  @override
  bool triggered() {
    var reservoir = PropertiesData().reservoir;
    if (reservoir == null) {
      return true;
    }
    return reservoir < 20;
  }
}
