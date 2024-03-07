import 'dart:math';

import 'package:carer/models/models.dart';
import 'package:carer/models/settings/debug_settings.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SettingsList(
            sections: [
              nightscoutSection(context, settings),
              unitsSection(settings),
              uiSection(settings),
              alarmSection(settings),
              debugSection(settings),
            ],
          ));
    });
  }

  SettingsSection nightscoutSection(BuildContext context, Settings settings) {
    // ensuring the text values
    var maxWidth =
        min(650, max(0, MediaQuery.of(context).size.width - 200)).toDouble();
    return SettingsSection(
      title: const Text('Nightscout'),
      tiles: [
        SettingsTile.navigation(
          title: const Text('URL'),
          value: Container(
            alignment: Alignment.centerRight,
            width: maxWidth,
            child: Text(
              settings.nightscoutURL,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          leading: const Icon(Icons.language),
          onPressed: (context) async {
            final url = await openTextDialog(context, "Nightscout URL",
                hint: "URL", value: settings.nightscoutURL);
            if (url == null || url.isEmpty) return;
            settings.nightscoutURL = url;
          },
        ),
      ],
    );
  }

  SettingsSection unitsSection(Settings settings) {
    var unit = settings.unit;
    var high = settings.targetHigh.toDouble();
    var low = settings.targetLow.toDouble();
    var highStr = unit.str(high);
    var lowStr = unit.str(low);

    var uhigh = settings.urgentHigh.toDouble();
    var ulow = settings.urgentLow.toDouble();
    var uhighStr = unit.str(uhigh);
    var ulowStr = unit.str(ulow);

    const minRange = 50.0;
    const maxRange = 280.0;
    double diff = 1;
    if (unit == Unit.mmol) {
      diff = 1.8;
    }

    return SettingsSection(
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Units'),
          trailing: Text(settings.unit.name),
          initialValue: settings.unit.toBool(),
          onToggle: (value) async {
            var unitP = UnitExtension.fromBool(value);
            settings.unit = unitP;
          },
        ),
        SettingsTile(
          //title: Text('Range High ${settings.rangeHigh}'),
          title: Row(children: [
            const Expanded(flex: 2, child: Text("Target")),
            Expanded(
                flex: 1,
                child: InkWell(
                    child: Text(lowStr, textAlign: TextAlign.end),
                    onTap: () {
                      settings.targetLow =
                          max(minRange, settings.targetLow.toDouble() - diff)
                              .toInt();
                    })),
            Expanded(
                flex: 6,
                child: Container(
                    alignment: Alignment.center,
                    height: 20,
                    child: RangeSlider(
                      values: RangeValues(low, high),
                      divisions: 230,
                      min: minRange,
                      max: maxRange,
                      onChanged: (RangeValues vals) {
                        var newLow = vals.start.toInt();
                        var newHigh = vals.end.toInt();
                        settings.targetLow = newLow;
                        settings.targetHigh = newHigh;
                      },
                    ))),
            Expanded(
              flex: 1,
              child: InkWell(
                  child: Text(
                    highStr,
                    textAlign: TextAlign.start,
                  ),
                  onTap: () {
                    settings.targetHigh =
                        min(maxRange, settings.targetHigh.toDouble() + diff)
                            .toInt();
                  }),
            ),
          ]),
        ),
        SettingsTile(
          //title: Text('Range High ${settings.rangeHigh}'),
          title: Row(children: [
            const Expanded(flex: 2, child: Text("Urgent")),
            Expanded(
                flex: 1,
                child: InkWell(
                    child: Text(ulowStr, textAlign: TextAlign.end),
                    onTap: () {
                      settings.urgentLow =
                          max(minRange, settings.urgentLow.toDouble() - diff)
                              .toInt();
                    })),
            Expanded(
                flex: 6,
                child: Container(
                    alignment: Alignment.center,
                    height: 20,
                    child: RangeSlider(
                      values: RangeValues(ulow, uhigh),
                      divisions: 230,
                      min: minRange,
                      max: maxRange,
                      onChanged: (RangeValues vals) {
                        settings.urgentLow = vals.start.toInt();
                        settings.urgentHigh = vals.end.toInt();
                      },
                    ))),
            Expanded(
              flex: 1,
              child: InkWell(
                child: Text(uhighStr, textAlign: TextAlign.start),
                onTap: () {
                  settings.urgentHigh =
                      min(maxRange, settings.urgentHigh.toDouble() + diff)
                          .toInt();
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }

  SettingsSection uiSection(Settings settings) {
    return SettingsSection(
      title: const Text('UI'),
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Keep Screen Active'),
          initialValue: settings.screenActive,
          onToggle: (value) async {
            settings.screenActive = value;
          },
        ),
        SettingsTile(
          title: const Text("Boundary Alarms"),
          trailing: ToggleButtons(
            isSelected: [
              settings.uiSettings.showChart,
              settings.uiSettings.showHistory,
              settings.uiSettings.showStats,
            ],
            onPressed: (int index) {
              switch (index) {
                case 0:
                  settings.uiSettings.showChart =
                      !settings.uiSettings.showChart;
                  break;
                case 1:
                  settings.uiSettings.showHistory =
                      !settings.uiSettings.showHistory;
                  break;
                case 2:
                  settings.uiSettings.showStats =
                      !settings.uiSettings.showStats;
                  break;
              }
            },
            children: [
              littleTextBigIcon("Chart", UniconsLine.chart_line),
              littleTextBigIcon("History", UniconsLine.history),
              littleTextBigIcon("Stats", UniconsLine.chart_pie_alt),
            ],
          ),
        ),
      ],
    );
  }

  SettingsSection alarmSection(Settings settings) {
    return SettingsSection(
      title: const Text('Alarms'),
      tiles: [
        SettingsTile(
          title: const Text("Boundary Alarms"),
          trailing: ToggleButtons(
            isSelected: [
              settings.alarmSettings.urgentLowAlarm,
              settings.alarmSettings.lowAlarm,
              settings.alarmSettings.highAlarm,
              settings.alarmSettings.urgentHighAlarm,
            ],
            onPressed: (int index) {
              switch (index) {
                case 0:
                  settings.alarmSettings.urgentLowAlarm =
                      !settings.alarmSettings.urgentLowAlarm;
                  break;
                case 1:
                  settings.alarmSettings.lowAlarm =
                      !settings.alarmSettings.lowAlarm;
                  break;
                case 2:
                  settings.alarmSettings.highAlarm =
                      !settings.alarmSettings.highAlarm;
                  break;
                case 3:
                  settings.alarmSettings.urgentHighAlarm =
                      !settings.alarmSettings.urgentHighAlarm;
                  break;
              }
            },
            children: [
              littleTextBigIcon("Urgent Low", UniconsLine.angle_double_down),
              littleTextBigIcon("Low", UniconsLine.angle_down),
              littleTextBigIcon("High", UniconsLine.angle_up),
              littleTextBigIcon("Urgent High", UniconsLine.angle_double_up),
            ],
          ),
        ),
        SettingsTile(
          title: const Text("Difference Alarms"),
          trailing: ToggleButtons(
            isSelected: [
              settings.alarmSettings.fastDropAlarm,
              settings.alarmSettings.fastRiseAlarm,
            ],
            onPressed: (int index) {
              switch (index) {
                case 0:
                  settings.alarmSettings.fastDropAlarm =
                      !settings.alarmSettings.fastDropAlarm;
                  break;
                case 1:
                  settings.alarmSettings.fastRiseAlarm =
                      !settings.alarmSettings.fastRiseAlarm;
                  break;
              }
            },
            children: [
              littleTextBigIcon("Fast Drop", UniconsLine.arrow_down_left),
              littleTextBigIcon("Fast Rise", UniconsLine.arrow_up_left),
            ],
          ),
        )
      ],
    );
  }

  Widget littleTextBigIcon(String text, IconData icon) {
    return Container(
        child: Column(
      children: [
        Icon(icon, size: 35),
        Text(text, style: const TextStyle(fontSize: 8, height: 0.5)),
      ],
    ));
  }

  SettingsSection debugSection(Settings settings) {
    var debugSettings = [];
    if (settings.debug) {
      // Add debugSummary Selector
      debugSettings.add(SettingsTile(
        title: Row(children: [
          const Text('Debug Summary'),
          Container(
              alignment: Alignment.centerRight,
              child: DropdownButton(
                value: settings.debugSummary,
                onChanged: (DebugSummary? value) {
                  if (value == null) return;
                  settings.debugSummary = value;
                },
                items: DebugSummary.values
                    .map<DropdownMenuItem<DebugSummary>>((e) {
                  return DropdownMenuItem<DebugSummary>(
                    value: e,
                    child: Text(e.name),
                  );
                }).toList(),
              ))
        ]),
      ));
    }

    return SettingsSection(
      title: const Text('Debug'),
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Debug'),
          initialValue: settings.debug,
          leading: const Icon(UniconsLine.bug),
          onToggle: (value) async {
            settings.debug = value;
          },
        ),
        ...debugSettings,
      ],
    );
  }

  ////
  // Dialog
  ////
  Future<String?> openTextDialog(BuildContext context, String title,
      {String hint = "", String value = ""}) {
    controller.value = TextEditingValue(text: value);
    // TODO add http regex validator
    return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: TextField(
                decoration: InputDecoration(hintText: hint),
                autofocus: true,
                controller: controller,
              ),
              actions: [
                TextButton(
                    onPressed: () =>
                        {Navigator.of(context).pop(controller.text)},
                    child: const Text("Save"))
              ],
            ));
  }

  Future<int?> openSliderDialog(BuildContext context, String title,
      {String hint = "", int value = 0}) {
    double currentSliderValue = value.toDouble();
    return showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Slider(
                  value: value.toDouble(),
                  autofocus: true,
                  max: 300,
                  min: 100,
                  divisions: 20,
                  label: currentSliderValue.round().toString(),
                  onChanged: (double value) {
                    currentSliderValue = value;
                  }),
              actions: [
                TextButton(
                    onPressed: () =>
                        {Navigator.of(context).pop(currentSliderValue.toInt())},
                    child: const Text("Save"))
              ],
            ));
  }
}
