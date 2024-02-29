import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    const heading =
        TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      var history = historyContainers(settings, summaryCn);

      return Window(
        title: "History",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.center,
                  child: DataTable(
                      columnSpacing: 5,
                      dividerThickness: 0.01,
                      headingRowHeight: 12,
                      dataRowMinHeight: 14,
                      dataRowMaxHeight: 18,
                      horizontalMargin: 0,
                      columns: const [
                        DataColumn(
                            label: SizedBox(
                                width: 50, child: Text('ago', style: heading))),
                        DataColumn(
                            label: SizedBox(
                                width: 50,
                                child: Text('insulin', style: heading))),
                        DataColumn(
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
    history = history.map((treatment) {
      treatment.unit = settings.unit;
      return treatment;
    }).toList();

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
        DataCell(
          Text(
            Dates.dateAgoShort(treatment.age),
            overflow: TextOverflow.ellipsis,
            style: row,
          ),
        ),
        DataCell(
          Text(
            treatment.insulinStr,
            style: row,
          ),
        ),
        DataCell(
          Text(
            treatment.carbStr,
            style: row,
          ),
        ),
      ]);
    }

    return null;
  }
}
