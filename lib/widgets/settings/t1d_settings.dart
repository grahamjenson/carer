import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/target_range_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

import '../../services/settings/alarm_settings.dart';

class TargetSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const TargetSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    List<ASignal<dynamic>> dependencies = [];
    dependencies.addAll(TargetSettings().allSignals());
    dependencies.add(UISettings().unitSignal);

    return AWatch(
      (context) {
        if (AlarmSettings().disableAlarms) {
          // Target and Urgent are still useful even with disabled alarms
          return SettingsSection(
            title: const Text('Targets'),
            tiles: [
              getTargetSettings(dependencies),
              getUrgentSettings(dependencies),
            ],
          );
        }

        return SettingsSection(
          title: const Text('Targets'),
          tiles: [
            getTargetSettings(dependencies),
            getUrgentSettings(dependencies),
            getDropRiseSettings(dependencies),
          ],
        );
      },
      debugLabel: "T1DSettingsWidget",
      dependencies: dependencies,
    );
  }

  SettingsTile getTargetSettings(List<ASignal<dynamic>> dependencies) {
    return SettingsTile(
        title: TargetRangeSlider(
      title: "Target",
      getLow: () => TargetSettings().lowTarget,
      getHigh: () => TargetSettings().highTarget,
      setLow: (double val) => TargetSettings().lowTarget = val,
      setHigh: (double val) => TargetSettings().highTarget = val,
      getStr: (double val) => UISettings().unit.str(val),
      fromStr: (String str) => UISettings().unit.fromStr(str),
      minRange: MIN_TARGET,
      maxRange: MAX_TARGET,
      dependencies: dependencies,
    ));
  }

  SettingsTile getUrgentSettings(List<ASignal<dynamic>> dependencies) {
    return SettingsTile(
      title: TargetRangeSlider(
        title: "Urgent",
        getLow: () => TargetSettings().lowUrgent,
        getHigh: () => TargetSettings().highUrgent,
        setLow: (double val) => TargetSettings().lowUrgent = val,
        setHigh: (double val) => TargetSettings().highUrgent = val,
        getStr: (double val) => UISettings().unit.str(val),
        fromStr: (String str) => UISettings().unit.fromStr(str),
        minRange: MIN_TARGET,
        maxRange: MAX_TARGET,
        dependencies: dependencies,
      ),
    );
  }

  SettingsTile getDropRiseSettings(List<ASignal<dynamic>> dependencies) {
    return SettingsTile(
      title: TargetRangeSlider(
        title: "Drop/Rise",
        getLow: () => TargetSettings().fastDropDelta,
        getHigh: () => TargetSettings().fastRiseDelta,
        setLow: (double val) => TargetSettings().fastDropDelta = val,
        setHigh: (double val) => TargetSettings().fastRiseDelta = val,
        getStr: (double val) => val > 0 ? "+${UISettings().unit.str(val)}" : UISettings().unit.str(val),
        fromStr: (String str) => UISettings().unit.fromStr(str),
        minRange: -MAX_DELTA,
        maxRange: MAX_DELTA,
        dependencies: dependencies,
        signed: true,
      ),
    );
  }
}
