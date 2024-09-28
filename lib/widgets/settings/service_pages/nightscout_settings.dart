import 'dart:math';

import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

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
          return SettingsList(
            sections: [
              SettingsSection(
                title: const Text('Nightscout'),
                tiles: [
                  SettingsTile.navigation(
                    title: const Text('URL'),
                    value: Container(
                      alignment: Alignment.centerRight,
                      width: maxWidth,
                      child: AWatch((context) {
                        var nsURL = SecureSettings().nightscoutURL;
                        var nsToken = SecureSettings().nightscoutToken;
                        if (nsURL == null || nsURL.isEmpty || nsToken == null || nsToken.isEmpty) {
                          return const Text("Not Set");
                        }

                        return Text(
                          "$nsURL/?token=$nsToken",
                          overflow: TextOverflow.ellipsis,
                        );
                      }, debugLabel: "NightscoutSettingsWidget"),
                    ),
                    leading: const Icon(Icons.language),
                    onPressed: (context) async {
                      final url = await openTextDialog(context, "Nightscout URL", hint: "URL", value: SecureSettings().nightscoutURL ?? "");
                      if (url == null || url.isEmpty) return;

                      var uri = Uri.parse(url);
                      var token = uri.queryParameters["token"];
                      token ??= '';
                      var base = '${uri.scheme}://${uri.host}';

                      SecureSettings().nightscoutURL = base.toString();
                      SecureSettings().nightscoutToken = token;
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
                TextButton(onPressed: () => {Navigator.of(context).pop(controller.text)}, child: const Text("Save"))
              ],
            ));
  }
}
