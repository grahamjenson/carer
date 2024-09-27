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
    var timescale = const Duration(hours: 5);
    double columnSpacing = 5;
    double dividerThickness = 0.01;
    double headingRowHeight = 1;
    double dataRowMinHeight = 14;
    double dataRowMaxHeight = 27;
    double horizontalMargin = 0;

    return AWatch((context) {
      var _ = TimerService().minuteSignal.value; // Refresh every minute
      var treatments = TreatmentList.lastSixHours.value.getWindows(5);
      treatments = treatments.where((e) => e.age < timescale).toList();
      var history = [for (var t in treatments) historyRow(context, t)].where((row) => row != null).map((row) => row as DataRow).toList();

      return Window(
        title: "History",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.center,
                  child: DataTable(
                      border: TableBorder(
                        verticalInside: BorderSide(color: outlineColor(context).dim, width: 0.5),
                        horizontalInside: const BorderSide(color: Color.fromARGB(0, 0, 0, 0), width: 0.2),
                      ),
                      columnSpacing: columnSpacing,
                      dividerThickness: dividerThickness,
                      headingRowHeight: headingRowHeight,
                      dataRowMinHeight: dataRowMinHeight,
                      dataRowMaxHeight: dataRowMaxHeight,
                      horizontalMargin: horizontalMargin,
                      columns: [
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('      '))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('      '))),
                        DataColumn(numeric: true, label: Container(alignment: Alignment.center, child: const Text('      '))),
                      ],
                      rows: history))),
        ),
      );
    }, debugLabel: "History");
  }

  DataRow? historyRow(BuildContext context, Treatment treatment) {
    TextStyle heading = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color: primaryColor(context),
      height: 1,
    );

    TextStyle headingSmall = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      color: primaryColor(context),
      height: 1,
    );

    TextStyle row = const TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1,
    );

    TextStyle small = const TextStyle(
      fontSize: 15,
      height: 1,
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return DataRow(cells: [
      DataCell(dateAgoShort(treatment, heading, headingSmall)),
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
    if (treatment.insulin == 0) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${toMax2dp(treatment.insulin)}", "u"], styles: [row, small]);
  }

  Widget carbsSmartText(Treatment treatment, TextStyle row, TextStyle small) {
    if (treatment.carbs == 0) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: ["${treatment.carbs.round()}", "g"], styles: [row, small]);
  }
}
