import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/services/nightscout_service_settings.dart';
import 'package:flutter/material.dart';

class NightscoutSettingsPage extends StatelessWidget {
  const NightscoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nightscout Settings'),
      ),
      body: AWatch(
        (context) {
          return const NightScoutServiceSettings();
        },
        debugLabel: "NightscoutSettingsPage",
      ),
    );
  }
}
