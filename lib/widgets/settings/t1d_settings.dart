import 'dart:math';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/models/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

class T1DSettingsWidget extends AbstractSettingsSection {
  const T1DSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsCN>(builder: (context, settings, child) {
      return Watch((context) {
        var unit = SettingNames.unit.signal.value;
        var high = settings.targetHigh.toDouble();
        var low = settings.targetLow.toDouble();
        var highStr = unit.str(high);
        var lowStr = unit.str(low);

        var uhigh = settings.urgentHigh.toDouble();
        var ulow = settings.urgentLow.toDouble();
        var uhighStr = unit.str(uhigh);
        var ulowStr = unit.str(ulow);

        var deltaMax = 36.0;
        var drop = settings.alarmSettings.fastDropDelta;
        var dropStr = unit.str(drop);
        var rise = settings.alarmSettings.fastRiseDelta;
        var riseStr = unit.str(rise);

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
              trailing: Text(unit.name),
              initialValue: unit.toBool(),
              onToggle: (value) async {
                var unitP = UnitExtension.fromBool(value);
                SettingNames.unit.signal.value = unitP;
              },
            ),
            SettingsTile(
              title: Row(children: [
                const Expanded(flex: 2, child: Text("Target")),
                Expanded(
                    flex: 1,
                    child: InkWell(
                        child: Text(lowStr, textAlign: TextAlign.end),
                        onTap: () {
                          settings.targetLow = max(minRange,
                                  settings.targetLow.toDouble() - diff)
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
              title: Row(children: [
                const Expanded(flex: 2, child: Text("Urgent")),
                Expanded(
                    flex: 1,
                    child: InkWell(
                        child: Text(ulowStr, textAlign: TextAlign.end),
                        onTap: () {
                          settings.urgentLow = max(minRange,
                                  settings.urgentLow.toDouble() - diff)
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
            SettingsTile(
              title: Row(children: [
                const Expanded(flex: 2, child: Text("Drop/Rise")),
                Expanded(
                    flex: 1,
                    child: InkWell(
                        child: Text(dropStr, textAlign: TextAlign.end),
                        onTap: () {
                          settings.alarmSettings.fastDropDelta = min(
                                  minRange,
                                  settings.alarmSettings.fastDropDelta
                                          .toDouble() -
                                      diff)
                              .toInt();
                        })),
                Expanded(
                    flex: 6,
                    child: Container(
                        alignment: Alignment.center,
                        height: 20,
                        child: RangeSlider(
                          values: RangeValues(drop.toDouble(), rise.toDouble()),
                          divisions: (deltaMax * 2).round(),
                          min: -deltaMax,
                          max: deltaMax,
                          onChanged: (RangeValues vals) {
                            settings.alarmSettings.fastDropDelta =
                                vals.start.toInt();
                            settings.alarmSettings.fastRiseDelta =
                                vals.end.toInt();
                          },
                        ))),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    child: Text(riseStr, textAlign: TextAlign.start),
                    onTap: () {
                      settings.alarmSettings.fastRiseDelta = min(
                              maxRange,
                              settings.alarmSettings.fastRiseDelta.toDouble() +
                                  diff)
                          .toInt();
                    },
                  ),
                ),
              ]),
            ),
          ],
        );
      });
    });
  }
}
