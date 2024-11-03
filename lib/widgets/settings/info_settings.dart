import 'package:carer/models/details/info/info_service.dart';
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
          inactiveStat(context, Info.iob),
          inactiveStat(context, Info.cob),
          inactiveStat(context, Info.basal),
          inactiveStat(context, Info.target),
          inactiveStat(context, Info.currentProfile),
          inactiveStat(context, Info.todaysInRange),
          inactiveStat(context, Info.yesterdayInRange),
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

  SettingsTile inactiveStat(BuildContext context, Info stat) {
    Color? iconColor;

    var descriptionStyle = labelMedium(context).copyWith(color: onBackgroundColor(context));
    var statusStyle = labelSmall(context).copyWith(color: onBackgroundColor(context).dim);

    var (texts, styles) = stat.status(context, statusStyle, statusStyle);
    return SettingsTile(
      descriptionInlineIos: true,
      title: Text(stat.title),
      description: SmartText(texts: ["${stat.description}\n"] + texts, styles: [descriptionStyle] + styles),
      leading: Icon(stat.icon, color: iconColor),
    );
  }
}
