import 'package:carer/models/properties_data.dart';
import 'package:carer/services/platform_info_service.dart';
import 'package:carer/services/settings/status_settings.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:unicons/unicons.dart';

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
  notCharging(_NotCharging()),
  powerLow(_PowerLow()),
  silentOn(_SilentOn());

  final _StatusMethods _methods;

  const Status(this._methods);

  IconData get icon => _methods.icon;
  String get title => _methods.title;
  String get reason => _methods.reason;
  String get status => _methods.status;
  String get description => _methods.description;
  bool triggered() => _methods.triggered();
}

class _CannulaChange extends _StatusMethods {
  const _CannulaChange();

  @override
  String get title => "Cannula Change";

  @override
  String get description => "Shows 24 hours before change";

  @override
  IconData get icon => UniconsLine.mobile_android;

  @override
  String get status {
    var hours = hoursLeft;
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Cannula ($daysOld days old) change $hoursStr";
  }

  @override
  String get reason {
    var hours = hoursLeft;
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Cannula Change $hoursStr";
  }

  int get hoursLeft {
    var cage = PropertiesData().cage;
    var cageExpiry = cage.add(StatusSettings().cannulaDuration);
    var hours = cageExpiry.difference(clock.now()).inHours;
    return hours;
  }

  int get daysOld {
    var cage = PropertiesData().cage;
    return clock.now().difference(cage).inDays;
  }

  @override
  bool triggered() {
    return hoursLeft < 24;
  }
}

class _SensorChange extends _StatusMethods {
  const _SensorChange();

  @override
  String get title => "Sensor Change";

  @override
  String get description => "Shows 24 hours before change";

  @override
  IconData get icon => UniconsLine.processor;

  @override
  String get status {
    var hours = hoursLeft;
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Sensor ($daysOld days old) Change $hoursStr";
  }

  @override
  String get reason {
    var hours = hoursLeft;
    var hoursStr = "in ${hours}h";
    if (hours < 1) {
      hoursStr = "NOW";
    }
    return "Sensor Change $hoursStr";
  }

  int get hoursLeft {
    var sage = PropertiesData().sage;
    var sageExpiry = sage.add(StatusSettings().sensorDuration);
    var hours = sageExpiry.difference(clock.now()).inHours;
    return hours;
  }

  int get daysOld {
    var sage = PropertiesData().sage;
    return clock.now().difference(sage).inDays;
  }

  @override
  bool triggered() {
    return hoursLeft < 24;
  }
}

class _NotCharging extends _StatusMethods {
  const _NotCharging();

  @override
  String get title => "Not Charging";

  @override
  String get description => "Shows When Phone is not Charging";

  @override
  IconData get icon => UniconsLine.bolt_slash;

  @override
  String get status {
    List<String> tooltip = [];

    var thisChargingStr = PlatformInfoService().thisPhoneIsCharging() ? "Charging" : "Not Charging";
    var t1dPhoneChargingStr = PropertiesData().t1dPhoneIsCharging() ? "Charging" : "Not Charging";

    tooltip.add("T1D Phone Battery(${PropertiesData().battery.toInt()}%) $t1dPhoneChargingStr");
    tooltip.add("Battery(${PlatformInfoService().batteryLevel.value}%) $thisChargingStr");
    return tooltip.join("\n");
  }

  @override
  String get reason {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var t1dPhonesCharging = PropertiesData().t1dPhoneIsCharging();

    List<String> tooltip = [];

    if (!thisPhonesCharging) {
      tooltip.add("Battery(${PlatformInfoService().batteryLevel.value}%) Not Charging");
    }
    if (!t1dPhonesCharging) {
      tooltip.add("T1D Phone Battery(${PropertiesData().battery.toInt()}%) Not Charging");
    }
    return tooltip.join("\n");
  }

  @override
  bool triggered() {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var t1dPhonesCharging = PropertiesData().t1dPhoneIsCharging();

    return !thisPhonesCharging || !t1dPhonesCharging;
  }
}

class _PowerLow extends _StatusMethods {
  const _PowerLow();

  @override
  String get title => "Power Low";

  @override
  String get description => "Shows When Phone Battery is below 30%";

  @override
  IconData get icon => UniconsLine.battery_empty;

  @override
  String get status {
    List<String> tooltip = [];

    tooltip.add("T1D Phone Battery(${PropertiesData().battery.toInt()}%)");
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
      var t1dPhonesBatteryLevel = PropertiesData().t1dPhonesBatteryLevel();
      tooltip.add("T1D Phones Battery < 30%($t1dPhonesBatteryLevel%)");
    }

    return tooltip.join("\n");
  }

  bool thisPhoneLowPower() {
    var thisPhonesCharging = PlatformInfoService().thisPhoneIsCharging();
    var thisPhonesBattery = PlatformInfoService().thisPhonesBatteryLevel();
    return !thisPhonesCharging && thisPhonesBattery < 30;
  }

  bool t1dPhoneLowPower() {
    var t1dPhonesCharging = PropertiesData().t1dPhoneIsCharging();
    var t1dPhonesBatteryLevel = PropertiesData().t1dPhonesBatteryLevel();
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
  IconData get icon => UniconsLine.bell_slash;

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

///
// SERVICE
////
class StatusService {
  static final StatusService _singleton = StatusService._();
  factory StatusService() => _singleton;

  StatusService._();
}
