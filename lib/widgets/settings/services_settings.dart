import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/settings/service_pages/nightscout_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

class ServicesSettingsWidget extends AbstractSettingsSection {
  ServicesSettingsWidget({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: const Text('Services'),
      tiles: [
        nightScoutSettings(),
      ],
    );
  }

  SettingsTile nightScoutSettings() {
    var description = "Not Set";

    if (SecureSettings().nightscoutURL != null) {
      var lastFetched = NSClient().lastFetched.value;
      var lastError = NSClient().lastError.value;
      var times = [];
      if (lastFetched != null) {
        times.add("Fetched: ${Dates.dateAgoShortFromNow(lastFetched)}");
      }
      if (lastError != null) {
        times.add("Errored: ${Dates.dateAgoShortFromNow(lastError)}");
      }

      if (times.isNotEmpty) {
        description = times.join(", ");
      } else {
        description = "Not Called Yet";
      }
    }

    return SettingsTile.navigation(
      title: const Text("Nightscout"),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => NightscoutSettingsPage())),
    );
  }
}
