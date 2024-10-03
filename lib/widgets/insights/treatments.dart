import 'package:carer/models/sql/bolus.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/timer_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class Treatments extends StatelessWidget with ThemeMixin {
  Treatments({super.key});

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
      var treatments = Treatment.lastSixHours.value;
      treatments = treatments.where((e) => e.age < timescale).toList();
      var history = [for (var t in treatments) historyRow(context, t)].where((row) => row != null).map((row) => row as DataRow).toList();

      return Window(
        child: SingleChildScrollView(
            child: Container(
                alignment: Alignment.center,
                child: DataTable(
                    border: TableBorder(
                      verticalInside: BorderSide(color: outlineColor(context), width: 0.5),
                      horizontalInside: BorderSide(color: outlineColor(context), width: 0.2),
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
      );
    }, debugLabel: "History");
  }

  DataRow? historyRow(BuildContext context, Treatment treatment) {
    return DataRow(cells: [
      DataCell(dateAgoShort(context, treatment)),
      DataCell(insulinSmartText(context, treatment)),
      DataCell(carbsSmartText(context, treatment)),
    ]);
  }

  SmartText dateAgoShort(BuildContext context, Treatment treatment) {
    TextStyle row = bodyLarge(context).copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
      color: accentColor(context),
      height: 1,
    );

    TextStyle small = row.copyWith(
      fontSize: row.fontSize! / 2,
    );

    var diff = treatment.age;

    if (diff.inMinutes == 0) {
      return SmartText(texts: const ["now"], styles: [small]);
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

  Widget insulinSmartText(BuildContext context, Treatment treatment) {
    TextStyle row = headlineSmall(context).copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
      height: 1,
    );

    TextStyle smallSub = row.copyWith(fontFeatures: [const FontFeature.subscripts()]);

    if (treatment.bolus == null) {
      return const SizedBox.shrink();
    }

    if (treatment.bolus!.type == BolusType.smb) {
      return SmartText(
        texts: [
          "⁺${toMax2dp(treatment.bolus!.value)}",
          "u",
        ],
        styles: [
          row.copyWith(color: primaryColor(context)),
          smallSub.copyWith(color: primaryColor(context)),
        ],
      );
    }
    return SmartText(texts: [(toMax2dpStr(treatment.bolus!.value)), "u"], styles: [row, smallSub]);
  }

  Widget carbsSmartText(BuildContext context, Treatment treatment) {
    TextStyle row = headlineSmall(context).copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
      height: 1,
    );

    TextStyle small = row.copyWith(fontFeatures: [const FontFeature.subscripts()]);

    if (treatment.carbs == null) {
      return const SizedBox.shrink();
    }
    return SmartText(texts: [toMax2dpStr(treatment.carbs!.value), "g"], styles: [row, small]);
  }
}
