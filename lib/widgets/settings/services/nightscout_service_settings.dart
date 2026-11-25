import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/settings/shared/text_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class NightScoutServiceSettings extends StatefulWidget {
  const NightScoutServiceSettings({super.key});

  @override
  State<NightScoutServiceSettings> createState() => _NightScoutServiceSettingsState();
}

class _NightScoutServiceSettingsState extends State<NightScoutServiceSettings> {
  final TextEditingController _nsTextController = TextEditingController();

  TextStyle activeBtnTextStyle = const TextStyle(fontSize: 30, color: ColorSchemes.primaryColor);
  TextStyle nullBtnTextStyle = TextStyle(fontSize: 30, color: ColorSchemes.primaryColor.dim.dim);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var btnTextStyle = const TextStyle(fontSize: 30, color: ColorSchemes.primaryColor);
    ButtonStyle activeBtnStyle = ElevatedButton.styleFrom(
      backgroundColor: ColorSchemes.accentColor.dim.dim.dim,
      padding: const EdgeInsets.all(20),
      textStyle: btnTextStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      side: BorderSide(color: ColorSchemes.accentColor.dim.dim, width: 1), // Change border color here
    );

    onTestAndSavePressed() async {
      var (url, token) = SecureSettings().nightscoutURLAndTokenFromString(_nsTextController.text);
      var (bigErr, errMsg) = await go(NSClient().testNSUrlAndToken(url, token));
      if (bigErr != null) {
        errMsg = bigErr.toString();
      }

      if (errMsg != null) {
        ToastService().showError("NOT SAVED", description: "$errMsg");
      } else {
        ToastService().showSuccess("Saved NS URL and Token");
        SecureSettings().setNSValuesFromURL(_nsTextController.text);
      }
    }

    return AWatch(
      (context) {
        return SettingsList(
          sections: [
            SettingsSection(
              title: const Text("NightScout Service Settings"),
              tiles: [
                SettingsTile(
                  title: TextField(
                    key: const ValueKey("ns_setup_url"),
                    decoration: InputDecoration(
                      hintText: "https://example.com?token=your_token",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: ColorSchemes.accentColor, width: 1.5),
                      ),
                    ),
                    autofocus: true,
                    controller: _nsTextController,
                  ),
                  description: const TextWrap(percent: 0.8, child: Text("Set NightScout URL with Token")),
                  descriptionInlineIos: true,
                ),
                SettingsTile(
                  title: Center(
                    child: ElevatedButton(
                      style: activeBtnStyle,
                      onPressed: onTestAndSavePressed,
                      child: Text("Save", style: activeBtnTextStyle),
                    ),
                  ),
                ),
                SettingsTile(
                  title: const Text("Nightscout Base URL"),
                  description: TextWrap(child: Text(SecureSettings().nightscoutURL ?? "NONE")),
                  descriptionInlineIos: true,
                  leading: const Icon(Icons.link),
                  trailing: const Icon(Icons.copy_outlined),
                  onPressed: (context) {
                    final url = SecureSettings().nightscoutURL;
                    if (url != null && url.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: url)).then((_) {
                        ToastService().showSuccess('Copied URL!');
                      });
                    } else {
                      ToastService().showError('Nothing to copy');
                    }
                  },
                ),
                SettingsTile(
                  title: const Text("Nightscout TOKEN"),
                  description: TextWrap(child: Text(SecureSettings().nightscoutToken ?? "NONE")),
                  descriptionInlineIos: true,
                  leading: const Icon(Icons.security),
                  trailing: const Icon(Icons.copy_outlined),
                  onPressed: (context) {
                    final token = SecureSettings().nightscoutToken;
                    if (token != null && token.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: token)).then((_) {
                        ToastService().showSuccess('Copied Token!');
                      });
                    } else {
                      ToastService().showError('Nothing to copy');
                    }
                  },
                ),
                SettingsTile(
                  title: const Text("Nightscout Full URL"),
                  description: TextWrap(child: Text(SecureSettings().nightscoutURLWithToken ?? "NONE")),
                  descriptionInlineIos: true,
                  leading: const Icon(Icons.link),
                  trailing: const Icon(Icons.copy_outlined),
                  onPressed: (context) {
                    final fullUrl = SecureSettings().nightscoutURLWithToken;
                    if (fullUrl != null && fullUrl.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: fullUrl)).then((_) {
                        ToastService().showSuccess('Copied Full URL!');
                      });
                    } else {
                      ToastService().showError('Nothing to copy');
                    }
                  },
                ),
              ],
            ),
            howToTokenURL(context),
          ],
        );
      },
      debugLabel: "NightscoutServiceSettings",
      dependencies: SecureSettings().allSignals(),
    );
  }

  SettingsSection howToTokenURL(BuildContext context) {
    return SettingsSection(
      title: const Text("How to get Nightscout URL and TOKEN"),
      tiles: [
        SettingsTile(
            title: Center(
                child: Image.asset(
          'assets/nstoken.gif',
          width: 400,
          height: 200,
          fit: BoxFit.cover,
        ))),
        SettingsTile(
          title: MarkdownBody(
            data: StringAssets().nightScoutHelp,
            styleSheet: MarkdownStyleSheet.fromTheme(
              Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
