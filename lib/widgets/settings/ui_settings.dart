import 'package:carer/services/settings/time_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
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
            SettingsTile(
              title: const Text("Layout"),
              trailing: DropdownButton(
                alignment: Alignment.topLeft,
                items: UILayout.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: SizedBox(width: 130, child: Text(e.viewName)),
                        ))
                    .toList(),
                value: UISettings().layout,
                onChanged: (value) {
                  if (value == null) return;
                  UISettings().layout = value;
                },
              ),
            ),
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

    String overrideText = "Start Night";
    bool isNightModeOverride = TimeSettings().isNightModeOverride();
    List<Widget> overrideButtons = [const SizedBox.shrink()];
    if (isNightModeOverride) {
      overrideText = "Stop Night";
    }
    if (!TimeSettings().isNight() || TimeSettings().isNightModeOverride()) {
      overrideButtons = [
        SizedBox(
            child: ElevatedButton(
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ))),
        const VerticalDivider(
          width: 20,
        ),
      ];
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
        children: overrideButtons + [timeSettings],
      ),
    );
  }
}
