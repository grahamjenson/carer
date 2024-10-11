import 'dart:async';

import 'package:carer/models/properties_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSPropertiesUpdater extends Updater {
  NSPropertiesUpdater() : super(intervalToCheck: const Duration(seconds: 1), maxAgeBeforeChecking: const Duration(seconds: 15)) {
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURLAndToken;
      addExternalReason("NS URL updated");
    }, debugLabel: "NSPropertiesUpdaterReason-NSURL");

    aeffect(() {
      addExternalReason("Resumed");
    }, debugLabel: "NSPropertiesUpdaterReason-LastResumed");
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
    var (properties, err) = await go(NSClient().getProperties(nsURL, nsToken));

    if (err != null || properties == null) {
      return false;
    }

    raw = properties.raw;

    if (properties.battery != null) {
      PropertiesData().setBattery(properties.battery!.toDouble());
    }
    if (properties.batteryDisplay != null) {
      PropertiesData().setBatteryDisplay(properties.batteryDisplay!);
    }
    if (properties.iob != null) {
      PropertiesData().setIOB(properties.iob!.toDouble());
    }
    if (properties.basaliob != null) {
      PropertiesData().setIOBBasal(properties.basaliob!.toDouble());
    }
    if (properties.treatmentIob != null) {
      PropertiesData().setIOBTreatment(properties.treatmentIob!.toDouble());
    }
    if (properties.cob != null) {
      PropertiesData().setCOB(properties.cob!.toDouble());
    }
    if (properties.cannulaChangeTime != null) {
      PropertiesData().setCAge(properties.cannulaChangeTime!.toDouble());
    }
    if (properties.sensorChangeTime != null) {
      PropertiesData().setSAge(properties.sensorChangeTime!.toDouble());
    }

    alog('''update properties:
      battery: ${properties.battery}
      batteryDisplay: ${properties.batteryDisplay}
      iob: ${properties.iob}
      basaliob: ${properties.basaliob}
      treatmentIob: ${properties.treatmentIob}
      cob: ${properties.cob}
      cannulaChangeTime: ${properties.cannulaChangeTime}
      sensorChangeTime: ${properties.sensorChangeTime}
    ''');

    return true;
  }
}
