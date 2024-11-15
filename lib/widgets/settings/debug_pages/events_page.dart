import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/sql/events/alarm_event.dart';
import 'package:carer/models/sql/events/app_state_change_event.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:carer/models/sql/events/snooze_events.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget with ThemeMixin {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Page'),
      ),
      body: AWatch(
        (context) {
          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: timelineRows(context),
            ),
          );
        },
        debugLabel: "AlarmLogPage",
      ),
    );
  }

  Widget timelineRows(BuildContext context) {
    List<EventModel> items = SQLToEvents().lastCoupleDays.value;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => logDbModelWidget(context, e)).toList(),
    );
  }

  Widget logDbModelWidget(BuildContext context, EventModel model) {
    TextStyle style = TextStyle(fontSize: 12, color: onBackgroundColor(context));

    // Square button with thick borders
    ButtonStyle btnStyle = ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(
            color: Colors.black,
            width: 2,
          ), // Border color and width
        ),
        minimumSize: const Size(400, 40), // Square size (width and height)
        padding: const EdgeInsets.all(10), // Remove default padding
        alignment: Alignment.centerLeft);

    if (model is AlarmEvent) {
      return Container(
          margin: const EdgeInsets.all(2),
          child: ElevatedButton.icon(
            style: btnStyle,
            icon: Icon(model.alarmType.icon, color: primaryColor(context)),
            label: Text(
              "${formatDate(model.startDate)}-${formatDate(model.endDate)}     ${model.alarmType.title} ${model.stage.name} ",
              style: style,
            ),
            onPressed: () {
              showLogModelDialog(context, model);
            },
          ));
    }

    if (model is SnoozeEvent) {
      return Container(
        margin: const EdgeInsets.all(2),
        child: ElevatedButton.icon(
          style: btnStyle,
          icon: Icon(
            CupertinoIcons.zzz,
            color: accentColor(context),
          ),
          label: Text(
            " ${formatDate(model.startDate)}-${formatDate(model.endDate)}     Snooze",
            style: style,
          ),
          onPressed: () {
            showLogModelDialog(context, model);
          },
        ),
      );
    }

    if (model is AppStateEvent) {
      return Container(
        margin: const EdgeInsets.all(2),
        child: ElevatedButton.icon(
          style: btnStyle,
          icon: Icon(
            model.stage == AppStateEventType.paused ? CupertinoIcons.pause : CupertinoIcons.play,
            color: accentColor(context),
          ),
          label: Text(
            " ${formatDate(model.startDate)}}     ${model.stage.name}",
            style: style,
          ),
          onPressed: () {
            showLogModelDialog(context, model);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget detailsWidget(BuildContext context, Map<String, dynamic> details) {
    List<String> detailsText = [];
    List<TextStyle> detailsStyle = [];
    details.forEach((key, value) {
      detailsText.add(key);
      detailsStyle.add(TextStyle(fontSize: 8, color: primaryColor(context)));
      detailsText.add("\t${truncateString(value.toString(), 100)}\n");
      detailsStyle.add(const TextStyle(fontSize: 8));
    });
    return SmartText(texts: detailsText, styles: detailsStyle);
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '?        ';
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void showLogModelDialog(BuildContext context, EventModel model) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(model.runtimeType.toString()),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Start: ${formatDate(model.startDate)}"),
              Text("End: ${formatDate(model.endDate)}"),
              detailsWidget(context, model.details),
            ],
          ),
        );
      },
    );
  }
}
