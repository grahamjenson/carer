import 'package:carer/models/sql/constants.dart';
import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/settings/togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class UISettingsWidget extends AbstractSettingsSection with ThemeMixin {
  const UISettingsWidget({super.key});

  static const double size = 50;

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var unit = UISettings().unit;
        var keepScreenActiveDescript = const Text('Keep the awake.\nWhen screen is asleep alarms wont work!');
        if (!UISettings().screenActive) {
          keepScreenActiveDescript = const Text(
            'Alarms wont work when screen is asleep!',
            style: TextStyle(color: ColorSchemes.primaryColor),
          );
        }
        return SettingsSection(
          title: const Text('UI'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Units'),
              trailing: Text(unit.name),
              initialValue: unit.toBool(),
              onToggle: (value) async {
                var unitP = Unit.fromBool(value);
                UISettings().unit = unitP;
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Keep Screen Active'),
              descriptionInlineIos: true,
              description: Flexible(child: keepScreenActiveDescript),
              initialValue: UISettings().screenActive,
              onToggle: (value) async {
                if (value) {
                  UISettings().screenActive = value;
                  return;
                }
                bool? areYouSure = await Dialogs.areYouSureDialog(
                    context, "Confirm Disable Screen Active", 'If Screen Falls Asleep Alarms will not work', "Disable");

                if (areYouSure == true) {
                  UISettings().screenActive = value;
                }
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Dim At Night'),
              description: const Text('Dim screen Colors at night'),
              descriptionInlineIos: true,
              initialValue: UISettings().enableDim,
              onToggle: (value) async {
                UISettings().enableDim = value;
              },
            ),
            timeSettingTile(context),
            overrideNightMode(context),
          ],
        );
      },
      debugLabel: "UISettingsWidget",
    );
  }

  SettingsTile overrideNightMode(BuildContext context) {
    bool isNightModeOverride = TimeSettings().isNightModeOverride();
    bool isDayModeOverride = TimeSettings().isDayModeOverride();

    String description = "";
    Function() onPressed = () => null;
    // Cancel The Override
    if (isNightModeOverride || isDayModeOverride) {
      description = "Cancel";
      onPressed = () async {
        TimeSettings().removeNightOverride();
      };
    } else if (TimeSettings().isDay()) {
      // Set Night Time until Sunrise
      description = "Night Until Sunrise";
      onPressed = () async {
        TimeSettings().nightModeOverride();
      };
    } else if (TimeSettings().isNight()) {
      // Set Day Time until Sunset
      description = "Day Until Sunset";
      onPressed = () async {
        TimeSettings().dayModeOverride();
      };
    }
    return SettingsTile.switchTile(
        title: const Text(
          "Override Night",
        ),
        description: Text(
          description,
        ),
        descriptionInlineIos: true,
        activeSwitchColor: errorColor(context),
        initialValue: isNightModeOverride || isDayModeOverride,
        onToggle: (value) {
          onPressed();
        });
  }

  SettingsTile timeSettingTile(BuildContext context) {
    return SettingsTile(
      title: Container(alignment: Alignment.centerLeft, height: 40, child: const Text('Night')),
      trailing: ToggleButtons(
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
                initialTime: TimeSettings().nightSunsetTime,
                initialEntryMode: TimePickerEntryMode.inputOnly,
              );
              if (value != null) {
                TimeSettings().nightSunsetTime = value;
              }
              break;
            case 1:
              TimeOfDay? value = await showTimePicker(
                context: context,
                initialTime: TimeSettings().nightSunriseTime,
                initialEntryMode: TimePickerEntryMode.inputOnly,
              );
              if (value != null) {
                TimeSettings().nightSunriseTime = value;
              }
              break;
          }
        },
        children: [
          ToggleButton(
            text: "Start\n${Dates.tODToString(TimeSettings().nightSunsetTime)}",
            height: size,
            width: size,
          ),
          ToggleButton(
            text: "End\n${Dates.tODToString(TimeSettings().nightSunriseTime)}",
            height: size,
            width: size,
          ),
        ],
      ),
    );
  }
}
