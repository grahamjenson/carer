import 'package:carer/models/settings.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController controller;
  String nightscoutUrl = '';
  String nightscoutToken = '';
  Unit unit = Unit.mmol;
  bool screenActive = true;

  Future<void> getSharedPrefs() async {
    var prefNightscoutUrl = await Settings.getNightScoutURL();
    var prefUnit = await Settings.getUnit();
    var prefScreenActive = await Settings.getScreenActive();

    setState(() {
      nightscoutUrl = prefNightscoutUrl;
      unit = prefUnit;
      screenActive = prefScreenActive;
    });
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: getSettings());
  }

  SettingsList getSettings() {
    return SettingsList(platform: DevicePlatform.iOS, sections: [
      nightscoutSection(),
      unitsSection(),
      screenSection(),
    ]);
  }

  SettingsSection nightscoutSection() {
    return SettingsSection(
      title: const Text('Nightscout'),
      tiles: [
        SettingsTile.navigation(
          title: const Text('URL'),
          value: Text(nightscoutUrl),
          leading: const Icon(Icons.language),
          onPressed: (context) async {
            final url = await openTextDialog("Nightscout URL",
                hint: "URL", value: nightscoutUrl);
            if (url == null || url.isEmpty) return;
            await Settings.setNightScoutURL(url);
            setState(() {
              nightscoutUrl = url;
            });
          },
        ),
      ],
    );
  }

  SettingsSection unitsSection() {
    return SettingsSection(
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Units'),
          trailing: Text(unit.name),
          initialValue: unit == Unit.mmol,
          onToggle: (value) async {
            var unitP = UnitExtension.fromBool(value);
            await Settings.setUnit(unitP);
            setState(() {
              unit = unitP;
            });
          },
        ),
      ],
    );
  }

  SettingsSection screenSection() {
    return SettingsSection(
      tiles: [
        SettingsTile.switchTile(
          title: const Text('Keep Screen Active'),
          initialValue: screenActive,
          onToggle: (value) async {
            await Settings.setScreenActive(value);
            setState(() {
              screenActive = value;
            });
          },
        ),
      ],
    );
  }

  Future<String?> openTextDialog(String title,
      {String hint = "", String value = ""}) {
    controller = TextEditingController(text: value);
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
