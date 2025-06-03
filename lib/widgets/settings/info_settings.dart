import 'package:carer/models/details/info/info_service.dart';
import 'package:carer/services/settings/status_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class InfoSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const InfoSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<SettingsTile> tiles = [
          infoTile(context, Info.iob),
          infoTile(context, Info.cob),
          infoTile(context, Info.basal),
          infoTile(context, Info.target),
          infoTile(context, Info.currentProfile),
          infoTile(context, Info.todaysInRange),
          infoTile(context, Info.yesterdayInRange),
        ];

        return SettingsSection(
          title: const Text('Info Settings'),
          tiles: tiles,
        );
      },
      debugLabel: "InfoSettingsWidget",
      dependencies: [TimerService().fifteenSecondSignal],
    );
  }

  SettingsTile infoTile(BuildContext context, Info stat) {
    StatusSettings statusSettings = StatusSettings();
    Color? iconColor;

    var descriptionStyle = labelMedium(context).copyWith(color: ColorSchemes.textColor);
    var statusStyle = labelSmall(context).copyWith(color: ColorSchemes.textColor.dim);

    var (texts, styles) = stat.status(context, statusStyle, statusStyle);
    return SettingsTile.switchTile(
      initialValue: statusSettings.infoEnabledContains(stat.name),
      onToggle: (bool value) {
        if (value) {
          statusSettings.infoEnabledAdd(stat.name);
        } else {
          statusSettings.infoEnabledRemove(stat.name);
        }
      },
      descriptionInlineIos: true,
      title: Text(stat.title),
      description: Flexible(child: SmartText(texts: ["${stat.description}\n"] + texts, styles: [descriptionStyle] + styles)),
      leading: Icon(stat.icon, color: iconColor),
    );
  }
}
