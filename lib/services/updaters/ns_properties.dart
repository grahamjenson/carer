import 'dart:async';

import 'package:carer/models/properties_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSPropertiesUpdater extends Updater {
  NSPropertiesUpdater() : super(intervalToCheck: const Duration(seconds: 5), maxAgeBeforeChecking: const Duration(seconds: 30)) {
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

    if (properties.iob != null) {
      PropertiesData().iob = properties.iob!.toDouble();
    }
    if (properties.basaliob != null) {
      PropertiesData().basaliob = (properties.basaliob!.toDouble());
    }
    if (properties.treatmentIob != null) {
      PropertiesData().treatmentiob = (properties.treatmentIob!.toDouble());
    }
    if (properties.cob != null) {
      PropertiesData().cob = (properties.cob!.toDouble());
    }
    if (properties.cannulaChangeTime != null) {
      PropertiesData().cage = DateTime.fromMillisecondsSinceEpoch(properties.cannulaChangeTime!);
    }
    if (properties.sensorChangeTime != null) {
      PropertiesData().sage = DateTime.fromMillisecondsSinceEpoch(properties.sensorChangeTime!);
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
