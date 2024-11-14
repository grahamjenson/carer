import 'package:carer/mappers/sql/logs/alarms_log.dart';
import 'package:carer/mappers/sql/logs/snooze_log.dart';
import 'package:carer/models/sql/logs/alarm_logs.dart';
import 'package:carer/models/sql/logs/log.dart';
import 'package:carer/models/sql/logs/snooze_logs.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class AlarmLogPage extends StatelessWidget with ThemeMixin {
  const AlarmLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Log Page'),
      ),
      body: AWatch(
        (context) {
          List<AlarmLog> alarmLogs = SQLToAlarmLogs().lastCoupleDays.value;
          List<SnoozeLog> snoozeLogs = SQLToSnoozeLogs().lastCoupleDays.value;

          List<LogDBModel> items = [];
          items.addAll(alarmLogs);
          items.addAll(snoozeLogs);

          items.sort((a, b) => b.date.compareTo(a.date));

          return Container(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final logModel = items[index];

                      List<Widget> children = [];

                      if (logModel is AlarmLog) {
                        children = [
                          Flexible(
                              flex: 1,
                              child: Text(
                                  '${logModel.type.name}\n${logModel.stage.name}\n${formatDate(logModel.startDate)}-${formatDate(logModel.endDate)}')),
                          Expanded(
                            flex: 3,
                            child: conditionsWidget(context, logModel.conditions),
                          )
                        ];
                      }

                      if (logModel is SnoozeLog) {
                        String text = 'Snooze\n${formatDate(logModel.startDate)}-${formatDate(logModel.endDate)}';

                        children = [
                          Flexible(flex: 1, child: Text(text)),
                          Expanded(
                            flex: 3,
                            child: conditionsWidget(context, logModel.conditions),
                          )
                        ];
                      }

                      return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        debugLabel: "AlarmLogPage",
      ),
    );
  }

  Widget conditionsWidget(BuildContext context, Map<String, dynamic> conditions) {
    List<String> conditionsText = [];
    List<TextStyle> conditionsStyle = [];
    conditions.forEach((key, value) {
      conditionsText.add(key);
      conditionsStyle.add(TextStyle(fontSize: 8, color: primaryColor(context)));
      conditionsText.add("\t${truncateString(value.toString(), 100)}\n");
      conditionsStyle.add(const TextStyle(fontSize: 8));
    });
    return SmartText(texts: conditionsText, styles: conditionsStyle);
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '?';
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
