import 'package:carer/mappers/sql/events.dart';
import 'package:carer/models/model.dart';
import 'package:carer/models/sql/events/alarm_event.dart';
import 'package:carer/models/sql/events/app_state_change_event.dart';
import 'package:carer/models/sql/events/background_event.dart';
import 'package:carer/models/sql/events/event.dart';
import 'package:carer/models/sql/events/snooze_events.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    List<EventModel> events = SQLToEvents().lastCoupleDays.value;
    List<Treatment> treatments = Treatment.last2days.value;

    List<DateMixin> items = [...events, ...treatments];
    items.sort((a, b) => b.date.compareTo(a.date));

    List<Widget> children = items.map((model) {
      if (model is AlarmEvent) {
        return eventHistoryRow(
          context,
          "${formatDate(model.startDate)}-${formatDate(model.endDate)}     ${model.alarmType.title} ${model.stage.name} ",
          model.alarmType.icon,
          primaryColor(context),
          () {
            showLogModelDialog(context, model);
          },
        );
      }
      if (model is SnoozeEvent) {
        return eventHistoryRow(
          context,
          " ${formatDate(model.startDate)}-${formatDate(model.endDate)}     Snooze",
          CarerIcons.EVENT_SNOOZE,
          accentColor(context),
          () {
            showLogModelDialog(context, model);
          },
        );
      }
      if (model is AppStateEvent) {
        return eventHistoryRow(
          context,
          " ${formatDate(model.startDate)}     App ${model.stage.name}",
          model.stage == AppStateEventType.paused ? CarerIcons.EVENT_APP_PAUSED : CarerIcons.EVENT_APP_RESUMED,
          accentColor(context),
          () {
            showLogModelDialog(context, model);
          },
        );
      }
      if (model is BackgroundEvent) {
        return eventHistoryRow(
          context,
          " ${formatDate(model.startDate)}     Background Event ${model.duration.inSeconds})",
          CarerIcons.EVENT_BACKGROUND,
          secondaryColor(context),
          () {
            showLogModelDialog(context, model);
          },
        );
      }
      if (model is Treatment) {
        return eventHistoryRow(
          context,
          " ${formatDate(model.date)}     ${model.isBolus ? "Bolus" : "Carb"} ${model.treatmentStr}${model.isSmb ? "*" : ""}",
          model.isBolus ? CarerIcons.EVENT_BOLUS : CarerIcons.EVENT_CARBS,
          model.isBolus ? accentColor(context).dim : primaryColor(context).dim,
          () {},
        );
      }

      return const SizedBox.shrink();
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget eventHistoryRow(BuildContext context, String text, IconData icon, Color iconColor, VoidCallback onPressed) {
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

    return Container(
      margin: const EdgeInsets.all(2),
      child: ElevatedButton.icon(
        style: btnStyle,
        icon: Icon(
          icon,
          color: iconColor,
        ),
        label: Text(
          text,
          style: style,
        ),
        onPressed: onPressed,
      ),
    );
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
                GoRouter.of(context).pop(); // Dismiss the dialog
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
