import 'dart:async';
import 'dart:math';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:signals/signals_flutter.dart';

class NightscoutSettingsWidget extends AbstractSettingsSection {
  NightscoutSettingsWidget({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            child: Watch((context) => Text(
                  Settings().nightscoutURL ?? "Not Set",
                  overflow: TextOverflow.ellipsis,
                )),
          ),
          leading: const Icon(Icons.language),
          onPressed: (context) async {
            final url = await openTextDialog(context, "Nightscout URL",
                hint: "URL", value: Settings().nightscoutURL ?? "");
            if (url == null || url.isEmpty) return;
            Settings().nightscoutURL = url;
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
