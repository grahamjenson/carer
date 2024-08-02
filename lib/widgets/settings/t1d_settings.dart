import 'dart:math';

import 'package:carer/models/constants.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class T1DSettingsWidget extends AbstractSettingsSection {
  const T1DSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var unit = UISettings().unit;
      var high = TargetSettings().highTarget.toDouble();
      var low = TargetSettings().lowTarget.toDouble();
      var highStr = unit.str(high);
      var lowStr = unit.str(low);

      var uhigh = TargetSettings().highUrgent.toDouble();
      var ulow = TargetSettings().lowUrgent.toDouble();
      var uhighStr = unit.str(uhigh);
      var ulowStr = unit.str(ulow);

      var deltaMax = 36.0;
      var drop = TargetSettings().fastDropDelta;
      var dropStr = unit.str(drop);
      var rise = TargetSettings().fastRiseDelta;
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
              UISettings().unit = unitP;
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
                        TargetSettings().lowTarget = max(minRange, TargetSettings().lowTargetPeek.toDouble() - diff).toInt();
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
                          TargetSettings().lowTarget = newLow;
                          TargetSettings().highTarget = newHigh;
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
                      TargetSettings().highTarget = min(maxRange, TargetSettings().highTargetPeek + diff).toInt();
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
                        TargetSettings().lowUrgent = max(minRange, TargetSettings().lowUrgentPeek - diff).toInt();
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
                          TargetSettings().lowUrgent = vals.start.toInt();
                          TargetSettings().highUrgent = vals.end.toInt();
                        },
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: Text(uhighStr, textAlign: TextAlign.start),
                  onTap: () {
                    TargetSettings().highUrgent = min(maxRange, TargetSettings().highUrgentPeek + diff).toInt();
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
                        var frd = TargetSettings().fastDropDeltaPeek;
                        TargetSettings().fastDropDelta = min(minRange, frd - diff).toInt();
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
                          TargetSettings().fastDropDelta = vals.start.toInt();
                          TargetSettings().fastRiseDelta = vals.end.toInt();
                        },
                      ))),
              Expanded(
                flex: 1,
                child: InkWell(
                  child: Text(riseStr, textAlign: TextAlign.start),
                  onTap: () {
                    var frd = TargetSettings().fastRiseDeltaPeek;
                    TargetSettings().fastRiseDelta = min(maxRange, frd + diff).toInt();
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
