import 'package:carer/models/treatments.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class History extends StatelessWidget with ThemeMixin {
  History({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle row = getRowTextStyle(context);
    TextStyle small = getSmallTextStyle(context);

    return AWatch((context) {
      var _ = TimerService().minuteSignal.value; // Refresh every minute

      var treatments = Treatment.lastSixHours.value;

      var history = [for (var t in treatments) historyRow(t, row, small)].where((row) => row != null).map((row) => row as DataRow).toList();

      return Window(
        title: "History",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.center,
                  child: DataTable(
                      border: TableBorder(
                        verticalInside: BorderSide(color: primaryColor(context), width: 0.2),
                        horizontalInside: BorderSide(color: primaryColor(context), width: 0.2),
                      ),
                      columnSpacing: 5,
                      dividerThickness: 0.01,
                      headingRowHeight: 12,
                      dataRowMinHeight: 14,
                      dataRowMaxHeight: 20,
                      horizontalMargin: 0,
                      columns: [
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text(''))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text(''))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text(''))),
                      ],
                      rows: history))),
        ),
      );
    });
  }

  DataRow? historyRow(Treatment treatment, TextStyle row, TextStyle small) {
    return DataRow(cells: [
      DataCell(dateAgoShort(treatment, row, small)),
      DataCell(insulinSmartText(treatment, row, small)),
      DataCell(carbsSmartText(treatment, row, small)),
    ]);
  }

  SmartText dateAgoShort(Treatment treatment, TextStyle row, TextStyle small) {
    var diff = treatment.age;

    if (diff.inMinutes == 0) {
      return SmartText(texts: const ["now"], styles: [row]);
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

  Widget insulinSmartText(Treatment treatment, TextStyle row, TextStyle small) {
    if (treatment.insulin == 0 || treatment.insulin == null) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${toMax2dp(treatment.insulin!)}", "u"], styles: [row, small]);
  }

  Widget carbsSmartText(Treatment treatment, TextStyle row, TextStyle small) {
    if (treatment.carbs == 0 || treatment.carbs == null) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${treatment.carbs!.round()}", "g"], styles: [row, small]);
  }
}
