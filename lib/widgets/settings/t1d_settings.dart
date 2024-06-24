import 'dart:math';

import 'package:carer/models/constants.dart';
import 'package:carer/signals/settings.dart';
import 'package:carer/signals/settings/alarm_settings.dart';
import 'package:carer/signals/settings/target_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class T1DSettingsWidget extends AbstractSettingsSection {
  const T1DSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      var unit = Settings().unit;
      var high = TargetSettings().targetHigh.toDouble();
      var low = TargetSettings().targetLow.toDouble();
      var highStr = unit.str(high);
      var lowStr = unit.str(low);

      var uhigh = TargetSettings().urgentHigh.toDouble();
      var ulow = TargetSettings().urgentLow.toDouble();
      var uhighStr = unit.str(uhigh);
      var ulowStr = unit.str(ulow);

      var deltaMax = 36.0;
      var drop = AlarmSettings().fastDropDelta;
      var dropStr = unit.str(drop);
      var rise = AlarmSettings().fastRiseDelta;
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
              Settings().unit = unitP;
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
                        TargetSettings().targetLow = max(
                                minRange,
                                TargetSettings().targetLowPeek.toDouble() -
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
                          TargetSettings().targetLow = newLow;
                          TargetSettings().targetHigh = newHigh;
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
                      TargetSettings().targetHigh =
                          min(maxRange, TargetSettings().targetHighPeek + diff)
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
                        TargetSettings().urgentLow =
                            max(minRange, TargetSettings().urgentLowPeek - diff)
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
                          TargetSettings().urgentLow = vals.start.toInt();
                          TargetSettings().urgentHigh = vals.end.toInt();
                        },
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: Text(uhighStr, textAlign: TextAlign.start),
                  onTap: () {
                    TargetSettings().urgentHigh =
                        min(maxRange, TargetSettings().urgentHighPeek + diff)
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
                        var frd = AlarmSettings().fastDropDeltaPeek;
                        AlarmSettings().fastDropDelta =
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
                          AlarmSettings().fastDropDelta = vals.start.toInt();
                          AlarmSettings().fastRiseDelta = vals.end.toInt();
                        },
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: Text(riseStr, textAlign: TextAlign.start),
                  onTap: () {
                    var frd = AlarmSettings().fastRiseDeltaPeek;
                    AlarmSettings().fastRiseDelta =
                        min(maxRange, frd + diff).toInt();
                  },
                ),
              ),
            ]),
          ),
        ],
      );
    });
  }
}
