import 'package:carer/models/treatments.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class History extends StatelessWidget with ThemeMixin {
  final bool minimal;
  History({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    TextStyle row = getRowTextStyle();
    TextStyle small = getSmallTextStyle();
    var timescale = const Duration(hours: 5);
    double columnSpacing = 5;
    double dividerThickness = 0.01;
    double headingRowHeight = 1;
    double dataRowMinHeight = 14;
    double dataRowMaxHeight = 20;
    double horizontalMargin = 0;

    if (minimal) {
      //Increase Text Size
      row = getRowTextStyle().copyWith(fontSize: 30);
      small = getSmallTextStyle().copyWith(fontSize: 20);
      timescale = const Duration(hours: 1);
      columnSpacing = 10;
      dividerThickness = 0.01;
      headingRowHeight = 1;
      dataRowMinHeight = 20;
      dataRowMaxHeight = 35;
      horizontalMargin = 5;
    }

    return AWatch((context) {
      var _ = TimerService().minuteSignal.value; // Refresh every minute
      var treatments = Treatment.lastSixHours.value;
      treatments = treatments.where((e) => e.age < timescale).toList();
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
