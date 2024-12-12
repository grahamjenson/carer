import 'dart:async';

import 'package:carer/models/properties_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSDeviceStatusUpdater extends Updater {
  NSDeviceStatusUpdater() : super(intervalToCheck: const Duration(seconds: 5), maxAgeBeforeChecking: const Duration(seconds: 15)) {
    aeffect(() {
      // Check signal to register
      var _ = SecureSettings().nightscoutURLAndToken;
      addExternalReason("NS URL updated");
    }, debugLabel: "NSDeviceStatusUpdaterReason-NSURL");

    aeffect(() {
      addExternalReason("Resumed");
    }, debugLabel: "NSDeviceStatusUpdaterReason-LastResumed");
  }

  @override
  Future<bool> update() async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
    var (ds, err) = await go(NSClient().getDeviceStatus(nsURL, nsToken));

    if (err != null || ds == null) {
      return false;
    }

    raw = ds.raw;

    if (ds.battery != null) {
      PropertiesData().battery = ds.battery!.toDouble();
    }
    if (ds.isCharging != null) {
      PropertiesData().isCharging = ds.isCharging!;
    }
    if (ds.reservoir != null) {
      PropertiesData().reservoir = ds.reservoir!.toDouble();
    }

    alog('''update DeviceStatus:
      battery: ${ds.battery}
      isCharging: ${ds.isCharging}
      reservoir: ${ds.reservoir}
    ''');

    return true;
  }
}
