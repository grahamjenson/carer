import 'dart:async';

import 'package:carer/models/properties_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/collection_updaters/collection.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/logs.dart';

class NSDeviceStatusUpdater extends NSCollection {
  @override
  Future<bool> bootstrap() async {
    return update(0);
  }

  @override
  String getCollectionName() {
    return "devicestatus";
  }

  @override
  Future<bool> update(int lastModified) async {
    var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
    var (ds, err) = await go(NSClient().getDeviceStatus(nsURL, nsToken));

    if (err != null || ds == null) {
      return false;
    }

    raw.add(ds.raw);

    if (ds.battery != null) {
      PropertiesData().t1dPhoneBattery = ds.battery!.toInt();
    }
    if (ds.isCharging != null) {
      PropertiesData().t1dPhoneCharging = ds.isCharging!;
    }
    if (ds.reservoir != null) {
      PropertiesData().reservoir = ds.reservoir!.toDouble();
    }

    if (ds.iob != null) {
      PropertiesData().iob = ds.iob!.toDouble();
    }
    if (ds.basaliob != null) {
      PropertiesData().basaliob = (ds.basaliob!.toDouble());
    }
    if (ds.treatmentIob != null) {
      PropertiesData().treatmentiob = (ds.treatmentIob!.toDouble());
    }
    if (ds.cob != null) {
      PropertiesData().cob = (ds.cob!.toDouble());
    }

    alog('''update DeviceStatus:
      battery: ${ds.battery}
      isCharging: ${ds.isCharging}
      reservoir: ${ds.reservoir}
      iob: ${ds.iob}
      basaliob: ${ds.basaliob}
      treatmentIob: ${ds.treatmentIob}
      cob: ${ds.cob}
    ''');

    return true;
  }
}
