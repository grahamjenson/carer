import 'package:carer/services/themes_service.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/services/updaters/updater.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
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
          var us = UpdateService();
          var nsSummaryUpdater = us.nsSummaryUpdater;
          var nsEntriesUpdater = us.nsEntriesUpdater;
          var nsTreatmentUpdater = us.nsTreatmentUpdater;
          var nsProfileUpdater = us.nsProfileUpdater;

          var list = [
            getUpdaterRow('Summary', nsSummaryUpdater),
            getUpdaterRow('Entries', nsEntriesUpdater),
            getUpdaterRow('Treatments', nsTreatmentUpdater),
            getUpdaterRow('Profile', nsProfileUpdater),
          ];
          return Container(
            margin: const EdgeInsets.all(12),
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                return list[index];
              },
            ),
          );
        },
        debugLabel: "NightScoutServiceDebugPage",
      ),
    );
  }

  Row getUpdaterRow(String name, Updater updater) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$name: ${updater.successfulAge.inMinutes}'),
        Text(prettyPrintJson(updater.raw) ?? ''),
      ],
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '?';
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
