import 'package:carer/services/stats_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class StatsSettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const StatsSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<SettingsTile> tiles = [
          inactiveStat(context, Stat.iob),
          inactiveStat(context, Stat.cob),
          inactiveStat(context, Stat.basal),
          inactiveStat(context, Stat.target),
          inactiveStat(context, Stat.currentProfile),
          inactiveStat(context, Stat.todaysInRange),
          inactiveStat(context, Stat.yesterdayInRange),
        ];

        return SettingsSection(
          title: const Text('Stats Settings'),
          tiles: tiles,
        );
      },
      debugLabel: "StatsSettingsWidget",
      dependencies: [TimerService().fifteenSecondSignal],
    );
  }

  SettingsTile inactiveStat(BuildContext context, Stat stat) {
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
