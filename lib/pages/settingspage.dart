import 'dart:ffi';
import 'dart:math';

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
              screenSection(settings),
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
            await settings.setNightscoutURL(url);
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

    return SettingsSection(
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Units'),
          trailing: Text(settings.unit.name),
          initialValue: settings.unit.toBool(),
          onToggle: (value) async {
            var unitP = UnitExtension.fromBool(value);
            await settings.setUnit(unitP);
          },
        ),
        SettingsTile(
          //title: Text('Range High ${settings.rangeHigh}'),
          title: Row(children: [
            const Expanded(flex: 2, child: Text("Target")),
            Expanded(flex: 1, child: Text(lowStr, textAlign: TextAlign.end)),
            Expanded(
                flex: 6,
                child: Container(
                    alignment: Alignment.center,
                    height: 20,
                    child: RangeSlider(
                      values: RangeValues(low, high),
                      divisions: 230,
                      min: 50,
                      max: 280,
                      onChanged: (RangeValues vals) {
                        var newLow = vals.start.toInt();
                        var newHigh = vals.end.toInt();
                        settings.setTargetLow(newLow);
                        settings.setTargetHigh(newHigh);
                      },
                    ))),
            Expanded(
                flex: 1,
                child: Text(
                  highStr,
                  textAlign: TextAlign.start,
                )),
          ]),
        ),
        SettingsTile(
          //title: Text('Range High ${settings.rangeHigh}'),
          title: Row(children: [
            const Expanded(flex: 2, child: Text("Urgent")),
            Expanded(flex: 1, child: Text(ulowStr, textAlign: TextAlign.end)),
            Expanded(
                flex: 6,
                child: Container(
                    alignment: Alignment.center,
                    height: 20,
                    child: RangeSlider(
                      values: RangeValues(ulow, uhigh),
                      divisions: 230,
                      min: 50,
                      max: 280,
                      onChanged: (RangeValues vals) {
                        settings.setUrgentLow(vals.start.toInt());
                        settings.setUrgentHigh(vals.end.toInt());
                      },
                    ))),
            Expanded(
                flex: 1, child: Text(uhighStr, textAlign: TextAlign.start)),
          ]),
        ),
      ],
    );
  }

  SettingsSection screenSection(Settings settings) {
    return SettingsSection(
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Keep Screen Active'),
          initialValue: settings.screenActive,
          onToggle: (value) async {
            await settings.setScreenActive(value);
          },
        ),
      ],
    );
  }

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
