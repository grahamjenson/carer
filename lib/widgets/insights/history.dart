import 'package:carer/models/treatments.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({super.key});

  static const heading = TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

  static const row = TextStyle(
    color: mainColor,
    fontSize: 20,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const small = TextStyle(
    color: mainColor,
    fontSize: 10,
  );

  static const superscript = TextStyle(
    color: mainColor,
    fontSize: 20,
    fontWeight: FontWeight.w100,
    fontFeatures: [FontFeature.superscripts()],
  );

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var _ = TimerService().minuteSignal.value; // Refresh every minute

      var treatments = Treatment.lastSixHours.value;

      var history = [for (var t in treatments) historyRow(t)].where((row) => row != null).map((row) => row as DataRow).toList();

      return Window(
        title: "History",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.center,
                  child: DataTable(
                      border: const TableBorder(
                        verticalInside: BorderSide(color: mainColor, width: 0.2),
                        horizontalInside: BorderSide(color: mainColor, width: 0.2),
                      ),
                      columnSpacing: 5,
                      dividerThickness: 0.01,
                      headingRowHeight: 12,
                      dataRowMinHeight: 14,
                      dataRowMaxHeight: 20,
                      horizontalMargin: 0,
                      columns: [
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('', style: heading))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('', style: heading))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('', style: heading))),
                      ],
                      rows: history))),
        ),
      );
    });
  }

  DataRow? historyRow(Treatment treatment) {
    return DataRow(cells: [
      DataCell(dateAgoShort(treatment)),
      DataCell(insulinSmartText(treatment)),
      DataCell(carbsSmartText(treatment)),
    ]);
  }

  SmartText dateAgoShort(Treatment treatment) {
    var diff = treatment.age;

    if (diff.inMinutes == 0) {
      return SmartText(texts: const ["now"], styles: const [row]);
    }

    List<String> texts = [];
    List<TextStyle> styles = [];
    if (diff.inHours > 0) {
      texts.add("${diff.inHours}");
      styles.add(row);
      texts.add("h");
      styles.add(small);
      texts.add((diff.inMinutes % 60).toString().padLeft(2, "0"));
      styles.add(row);
      texts.add("m");
      styles.add(small);

      return SmartText(texts: texts, styles: styles);
    }
    texts.add((diff.inMinutes % 60).toString());
    styles.add(row);
    texts.add("m");
    styles.add(small);

    return SmartText(texts: texts, styles: styles);
  }

  Widget insulinSmartText(Treatment treatment) {
    if (treatment.insulin == 0 || treatment.insulin == null) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${toMax2dp(treatment.insulin!)}", "u"], styles: const [row, small]);
  }

  Widget carbsSmartText(Treatment treatment) {
    if (treatment.carbs == 0 || treatment.carbs == null) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${treatment.carbs!.round()}", "g"], styles: const [row, small]);
  }
}
