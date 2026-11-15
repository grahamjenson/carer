import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:go_router/go_router.dart';

class ServicesSettingsWidget extends AbstractSettingsSection {
  ServicesSettingsWidget({super.key});
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        return SettingsSection(
          title: const Text('Services'),
          tiles: [
            nightScoutSettings(),
          ],
        );
      },
      debugLabel: "NightScoutSettingsWidget",
      dependencies: [NSClient.lastFetched, NSClient.totalErrors],
    );
  }

  SettingsTile nightScoutSettings() {
    var description = "Not Set";

    if (SecureSettings().nightscoutURLAndTokenSet()) {
      var lastFetched = NSClient.lastFetched.value;
      var lastError = NSClient.totalErrors.lastSet;
      var totalErrors = NSClient.totalErrors.value;

      var times = [];
      if (lastFetched != null) {
        times.add("Fetched ${Dates.dateAgoLongFromNow(lastFetched)} ago");
      } else {
        times.add("Not Fetched Yet");
      }

      times.add("Total Errors $totalErrors");
      if (totalErrors > 0) {
        times.add("Last Error ${Dates.dateAgoLongFromNow(lastError)} ago");
      }

      description = times.join("\n");
    }

    return SettingsTile.navigation(
      title: const Text("Nightscout"),
      description: Text(description),
      descriptionInlineIos: true,
      onPressed: (context) => GoRouter.of(context).go("/settings/nightscout"),
    );
  }
}
