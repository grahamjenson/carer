import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/target_range_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class TargetSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const TargetSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        return SettingsSection(
          title: const Text('Targets'),
          tiles: [
            SettingsTile(
                title: TargetRangeSlider(
              title: "Target",
              getLow: () => TargetSettings().lowTarget,
              getHigh: () => TargetSettings().highTarget,
              setLow: (double val) => TargetSettings().lowTarget = val,
              setHigh: (double val) => TargetSettings().highTarget = val,
              minRange: MIN_TARGET,
              maxRange: MAX_TARGET,
              dependencies: const [],
            )),
            SettingsTile(
              title: TargetRangeSlider(
                title: "Urgent",
                getLow: () => TargetSettings().lowUrgent,
                getHigh: () => TargetSettings().highUrgent,
                setLow: (double val) => TargetSettings().lowUrgent = val,
                setHigh: (double val) => TargetSettings().highUrgent = val,
                minRange: MIN_TARGET,
                maxRange: MAX_TARGET,
                dependencies: const [],
              ),
            ),
            SettingsTile(
              title: TargetRangeSlider(
                title: "Drop/Rise",
                getLow: () => TargetSettings().fastDropDelta,
                getHigh: () => TargetSettings().fastRiseDelta,
                setLow: (double val) => TargetSettings().fastDropDelta = val,
                setHigh: (double val) => TargetSettings().fastRiseDelta = val,
                minRange: -MAX_DELTA,
                maxRange: MAX_DELTA,
                dependencies: const [],
              ),
            ),
          ],
        );
      },
      debugLabel: "T1DSettingsWidget",
    );
  }
}
