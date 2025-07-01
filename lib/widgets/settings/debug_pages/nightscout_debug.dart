import 'dart:convert';

import 'package:carer/services/themes_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';

class NightScoutServiceDebugPage extends StatelessWidget with ThemeMixin {
  const NightScoutServiceDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NightScout Debug Page'),
      ),
      body: AWatch(
        (context) {
          final us = UpdateService();
          final updaters = {
            'Properties': us.nsPropertiesUpdater,
            'Entries': us.nsEntriesUpdater,
            'Treatments': us.nsTreatmentUpdater,
            'Profile': us.nsProfileUpdater,
            'DeviceStatus': us.nsDeviceStatusUpdater,
            'Bootstrap': us.nsBootstrap,
          };

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: updaters.length,
            itemBuilder: (context, index) {
              final entry = updaters.entries.elementAt(index);
              return _buildUpdaterTile(entry.key, entry.value);
            },
          );
        },
        debugLabel: "NightScoutServiceDebugPage",
      ),
    );
  }

  Widget _buildUpdaterTile(String name, Updater updater) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text('$name: ${updater.successfulAge.inMinutes} min ago'),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          SelectableText(
            _prettyPrintJson(updater.raw),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _prettyPrintJson(String input) {
    try {
      final decoded = const JsonDecoder().convert(input);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return pretty;
    } catch (_) {
      return input; // If not valid JSON, just return raw string
    }
  }
}
