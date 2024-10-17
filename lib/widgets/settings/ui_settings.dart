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
        var keepScreenActiveDescript = const Text('Keep the awake.\nWhen screen is asleep alarms wont work!');
        if (!UISettings().screenActive) {
          keepScreenActiveDescript = Text(
            'Alarms wont work when screen is asleep!',
            style: TextStyle(color: primaryColor(context)),
          );
        }
        return SettingsSection(
          title: const Text('UI'),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Keep Screen Active'),
              descriptionInlineIos: true,
              description: keepScreenActiveDescript,
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
              title: const Text('Dull At Night'),
              description: const Text('Dull screen Colors at night'),
              descriptionInlineIos: true,
              initialValue: UISettings().enableDim,
              onToggle: (value) async {
                UISettings().enableDim = value;
              },
            ),
            timeSettingTile(context),
          ],
        );
      },
      debugLabel: "UISettingsWidget",
    );
  }

  SettingsTile timeSettingTile(BuildContext context) {
    var buttonstyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(5),
      backgroundColor: Colors.transparent, // Remove padding
      minimumSize: const Size(50, 50), // Shrink the tap target size
      // Shrink the tap target size
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)), // Remove rounded boundaries
      ),
    );

    bool isNightModeOverride = TimeSettings().isNightModeOverride();
    bool isDayModeOverride = TimeSettings().isDayModeOverride();

    Widget overrideButton = const SizedBox.shrink();

    var btnH = 50.0;
    var btnW = 100.0;

    // Cancel The Override
    if (isNightModeOverride || isDayModeOverride) {
      overrideButton = SizedBox(
        height: btnH,
        width: btnW,
        child: ElevatedButton(
          style: buttonstyle,
          onPressed: () async {
            TimeSettings().removeNightOverride();
          },
          child: Text(
            "Cancel\nOverride",
            textAlign: TextAlign.center,
            style: labelSmall(context).copyWith(color: primaryColor(context)),
          ),
        ),
      );
    } else if (TimeSettings().isDay()) {
      // Set Night Time until Sunrise
      overrideButton = SizedBox(
        height: btnH,
        width: btnW,
        child: ElevatedButton(
          style: buttonstyle,
          onPressed: () async {
            TimeSettings().nightModeOverride();
          },
          child: Text(
            "Set Night\nUntil Sunrise",
            textAlign: TextAlign.center,
            style: labelSmall(context).copyWith(color: primaryColor(context)),
          ),
        ),
      );
    } else if (TimeSettings().isNight()) {
      overrideButton = SizedBox(
        height: btnH,
        width: btnW,
        child: ElevatedButton(
          style: buttonstyle,
          onPressed: () async {
            TimeSettings().dayModeOverride();
          },
          child: Text(
            "Set Day\nUntil Sunset",
            textAlign: TextAlign.center,
            style: labelSmall(context).copyWith(color: primaryColor(context)),
          ),
        ),
      );
    }

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
    );

    return SettingsTile(
      title: Container(alignment: Alignment.centerLeft, height: 40, child: const Text('Night')),
      trailing: Row(
        children: [overrideButton, const VerticalDivider(width: 20)] + [timeSettings],
      ),
    );
  }
}
