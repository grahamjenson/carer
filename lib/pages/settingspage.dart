import 'dart:math';

import 'package:carer/models/settings_cn.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';

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
}
