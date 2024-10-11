import 'package:carer/mappers/sql/alarms_log.dart';
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
          var alarmLogs = SQLToAlarmLogs().lastCoupleDays.value;
          return Container(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: alarmLogs.length,
                    itemBuilder: (context, index) {
                      final alarmLog = alarmLogs[index];
                      List<String> conditionsText = [];
                      List<TextStyle> conditionsStyle = [];
                      alarmLog.conditions.forEach((key, value) {
                        conditionsText.add(key);
                        conditionsStyle.add(TextStyle(fontSize: 8, color: primaryColor(context)));
                        conditionsText.add("\t${truncateString(value.toString(), 100)}\n");
                        conditionsStyle.add(const TextStyle(fontSize: 8));
                      });
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${alarmLog.type.name}\n${alarmLog.stage.name}\n${formatDate(alarmLog.startDate)}-${formatDate(alarmLog.endDate)}'),
                          SmartText(texts: conditionsText, styles: conditionsStyle),
                        ],
                      );
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

  String formatDate(DateTime? date) {
    if (date == null) {
      return '?';
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
