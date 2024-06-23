import 'dart:math';

import 'package:carer/change_notifiers/settings/alarm_settings.dart';
import 'package:carer/change_notifiers/settings/target_settings.dart';
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
        var unit = Settings.unit.value as Unit;
        var high = TargetSettings.targetHigh.value.toDouble();
        var low = TargetSettings.targetLow.value.toDouble();
        var highStr = unit.str(high);
        var lowStr = unit.str(low);

        var uhigh = TargetSettings.urgentHigh.value.toDouble();
        var ulow = TargetSettings.urgentLow.value.toDouble();
        var uhighStr = unit.str(uhigh);
        var ulowStr = unit.str(ulow);

        var deltaMax = 36.0;
        var drop = AlarmSettings.fastDropDelta.value;
        var dropStr = unit.str(drop);
        var rise = AlarmSettings.fastRiseDelta.value;
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
                var unitP = Unit.fromBool(value);
                Settings.unit.value = unitP;
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
                          TargetSettings.targetLow.value = max(
                                  minRange,
                                  TargetSettings.targetLow.peek.toDouble() -
                                      diff)
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
                            TargetSettings.targetLow.value = newLow;
                            TargetSettings.targetHigh.value = newHigh;
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
                        TargetSettings.targetHigh.value =
                            min(maxRange, TargetSettings.targetHigh.peek + diff)
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
                          TargetSettings.urgentLow.value = max(minRange,
                                  TargetSettings.urgentLow.peek - diff)
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
                            TargetSettings.urgentLow.value = vals.start.toInt();
                            TargetSettings.urgentHigh.value = vals.end.toInt();
                          },
                        ))),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    child: Text(uhighStr, textAlign: TextAlign.start),
                    onTap: () {
                      TargetSettings.urgentHigh.value =
                          min(maxRange, TargetSettings.urgentHigh.peek + diff)
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
                          var frd = (AlarmSettings.fastDropDelta.peek as int);
                          AlarmSettings.fastDropDelta.value =
                              min(minRange, frd - diff).toInt();
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
                            AlarmSettings.fastDropDelta.value =
                                vals.start.toInt();
                            AlarmSettings.fastRiseDelta.value =
                                vals.end.toInt();
                          },
                        ))),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    child: Text(riseStr, textAlign: TextAlign.start),
                    onTap: () {
                      var frd = (AlarmSettings.fastRiseDelta.peek as int);
                      AlarmSettings.fastRiseDelta.value =
                          min(maxRange, frd + diff).toInt();
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
