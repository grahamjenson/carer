import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class History extends StatelessWidget {
  const History({super.key});

  static const heading =
      TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

  static const row = TextStyle(
    color: mainColor,
    fontSize: 20,
  );
  static const small = TextStyle(
    color: mainColor,
    fontSize: 10,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      var history = historyContainers(settings, summaryCn);
      if (!settings.uiSettings.showHistory) {
        return const SizedBox.shrink();
      }

      return Window(
        title: "History",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.center,
                  child: DataTable(
                      border: const TableBorder(
                        verticalInside:
                            BorderSide(color: mainColor, width: 0.2),
                        horizontalInside:
                            BorderSide(color: mainColor, width: 0.2),
                      ),
                      columnSpacing: 5,
                      dividerThickness: 0.01,
                      headingRowHeight: 12,
                      dataRowMinHeight: 14,
                      dataRowMaxHeight: 20,
                      horizontalMargin: 0,
                      columns: const [
                        DataColumn(
                            numeric: true,
                            label: SizedBox(
                                width: 50, child: Text('ago', style: heading))),
                        DataColumn(
                            numeric: true,
                            label: SizedBox(
                                width: 50,
                                child: Text('insulin', style: heading))),
                        DataColumn(
                            numeric: true,
                            label: SizedBox(
                                width: 50,
                                child: Text('carbs', style: heading))),
                      ],
                      rows: history))),
        ),
      );
    });
  }

  List<DataRow> historyContainers(Settings settings, SummaryCN summaryCn) {
    if (summaryCn.summary.dateRetrieved == Dates.earliest) {
      return [];
    }
    var history = summaryCn.summary.treatments.summarizedTreatments(60 * 6, 5);

    return [for (var t in history) historyRow(t)]
        .where((row) => row != null)
        .map((row) => row as DataRow)
        .toList();
  }

  DataRow? historyRow(ATreatment treatment) {
    const row =
        TextStyle(color: mainColor, fontSize: 14, fontWeight: FontWeight.bold);

    if (treatment is SummaryTreatment) {
      return DataRow(cells: [
        DataCell(dateAgoShort(treatment.age)),
        DataCell(insulinSmartText(treatment)),
        DataCell(carbsSmartText(treatment)),
      ]);
    }

    return null;
  }

  SmartText dateAgoShort(Duration diff) {
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
    }
    texts.add("${diff.inMinutes % 60}");
    styles.add(row);
    texts.add("m");
    styles.add(small);
    return SmartText(texts: texts, styles: styles);
  }

  SmartText insulinSmartText(SummaryTreatment treatment) {
    return SmartText(
        texts: ["${treatment.insulin}", "u"], styles: const [row, small]);
  }

  SmartText carbsSmartText(SummaryTreatment treatment) {
    return SmartText(
        texts: ["${treatment.carbs}", "g"], styles: const [row, small]);
  }
}
