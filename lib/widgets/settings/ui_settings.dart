import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:carer/widgets/settings/ui_pages/theme_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class UISettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const UISettingsWidget({super.key});

  static const double size = 50;

  TextStyle getSmallTextStyle() {
    return const TextStyle(
      fontSize: 10,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        return SettingsSection(
          title: const Text('UI'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Keep Screen Active'),
              initialValue: UISettings().screenActive,
              onToggle: (value) async {
                UISettings().screenActive = value;
              },
            ),
            timeSettingTile(context),
            SettingsTile.navigation(
              title: Container(alignment: Alignment.centerLeft, height: 40, child: const Text('Themes')),
              leading: const Icon(Icons.palette),
              trailing: ToggleButtons(
                constraints: const BoxConstraints(maxHeight: size, maxWidth: size),
                renderBorder: true,
                borderRadius: BorderRadius.circular(10),
                borderWidth: 0,
                isSelected: [
                  true,
                  UISettings().alarmUIThemeLayout.enabled,
                  UISettings().nightUIThemeLayout.enabled,
                ],
                onPressed: (int index) async {
                  switch (index) {
                    case 0:
                      UISettings().mainUIThemeLayout.enabled = !UISettings().mainUIThemeLayout.enabled;
                      break;
                    case 1:
                      UISettings().alarmUIThemeLayout.enabled = !UISettings().alarmUIThemeLayout.enabled;
                      break;
                    case 2:
                      UISettings().nightUIThemeLayout.enabled = !UISettings().nightUIThemeLayout.enabled;
                      break;
                  }
                },
                children: [
                  ToggleButton(
                    text: "Main Layout\n${UISettings().mainUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                  ToggleButton(
                    text: "Alarm Layout\n${UISettings().alarmUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                  ToggleButton(
                    text: "Night Layout\n${UISettings().nightUIThemeLayout.theme.viewName}",
                    height: size,
                    width: size,
                  ),
                ],
              ),
              onPressed: (BuildContext context) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ThemePage()));
              },
            ),
          ],
        );
      },
      debugLabel: "UISettingsWidget",
    );
  }

  SettingsTile timeSettingTile(BuildContext context) {
    var isNightModeOverride = TimeSettings().isNightModeOverride();
    String overrideText = "Start\nOverride";
    if (isNightModeOverride) {
      overrideText = "Stop\nOverride";
    }

    var buttonstyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(5), // Remove padding
      minimumSize: Size.zero, // Remove minimum size constraints
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink the tap target size
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)), // Remove rounded boundaries
      ),
    );

    var timeSettings = ToggleButtons(
      renderBorder: true,
      constraints: const BoxConstraints(maxHeight: size, maxWidth: size),
      borderRadius: BorderRadius.circular(10),
      borderWidth: 0,
      isSelected: const [true, true],
      onPressed: (int index) async {
        switch (index) {
          case 0:
            TimeOfDay? value = await showTimePicker(
              context: context,
              initialTime: TimeSettings().nightStartTime,
              initialEntryMode: TimePickerEntryMode.inputOnly,
            );
            if (value != null) {
              TimeSettings().nightStartTime = value;
            }
            break;
          case 1:
            TimeOfDay? value = await showTimePicker(
              context: context,
              initialTime: TimeSettings().nightEndTime,
              initialEntryMode: TimePickerEntryMode.inputOnly,
            );
            if (value != null) {
              TimeSettings().nightEndTime = value;
            }
            break;
        }
      },
      children: [
        ToggleButton(
          text: "Start\n${Dates.tODToString(TimeSettings().nightStartTime)}",
          height: size,
          width: size,
        ),
        ToggleButton(
          text: "End\n${Dates.tODToString(TimeSettings().nightEndTime)}",
          height: size,
          width: size,
        ),
      ],
    );

    return SettingsTile(
      title: Container(alignment: Alignment.centerLeft, height: 40, child: const Text('Night')),
      trailing: Row(
        children: [
          ElevatedButton(
              style: buttonstyle,
              onPressed: () async {
                if (isNightModeOverride) {
                  TimeSettings().stopNightModeOverride();
                } else {
                  TimeSettings().nightModeOverride();
                }
              },
              child: Text(
                overrideText,
                style: getSmallTextStyle(),
              )),
          const VerticalDivider(
            width: 20,
          ),
          timeSettings
        ],
      ),
    );
  }
}
