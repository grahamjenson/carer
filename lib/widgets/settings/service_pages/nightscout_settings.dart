import 'dart:math';

import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class NightscoutSettingsPage extends StatelessWidget {
  NightscoutSettingsPage({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var maxWidth = min(650, max(0, MediaQuery.of(context).size.width - 200)).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nightscout Settings'),
      ),
      body: AWatch(
        (context) {
          var nsURL = SecureSettings().nightscoutURL;
          var nsToken = SecureSettings().nightscoutToken;
          var currentURL = "";
          var viewURL = "Not Set";
          if (nsURL != null && nsURL.isNotEmpty && nsToken != null && nsToken.isNotEmpty) {
            currentURL = "$nsURL/?token=$nsToken";
            viewURL = currentURL;
          }

          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Nightscout'),
                tiles: [
                  SettingsTile.navigation(
                    title: const Text('URL'),
                    value: Container(alignment: Alignment.centerRight, width: maxWidth, child: Text(viewURL, overflow: TextOverflow.ellipsis)),
                    onPressed: (context) async {
                      final url = await openTextDialog(context, "Nightscout URL", hint: "Nightscout URL", value: currentURL);
                      if (url == null || url.isEmpty) return;
                      SecureSettings().setNSValuesFromURL(url);
                    },
                  ),
                ],
              ),
            ],
          );
        },
        debugLabel: "NightscoutSettingsPage",
      ),
    );
  }

  Future<String?> openTextDialog(BuildContext context, String title, {String hint = "", String value = ""}) {
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
                TextButton(onPressed: () => {GoRouter.of(context).pop(controller.text)}, child: const Text("Save"))
              ],
            ));
  }
}
