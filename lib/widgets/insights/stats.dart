import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});
  static const TextStyle row = TextStyle(color: mainColor, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    const heading =
        TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      var summary = summaryCn.summary;
      return Container(
        margin: const EdgeInsets.only(left: 8),
        width: 140,
        decoration: BoxDecoration(
          border: Border.all(color: mainColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: mainColor,
              ),
              child: const Text("Stats",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 10,
                  )),
            ),
            Expanded(
              child: SingleChildScrollView(
                  child: Container(
                alignment: Alignment.center,
                child: DataTable(
                  columnSpacing: 5,
                  dividerThickness: 0.01,
                  headingRowHeight: 0,
                  dataRowMinHeight: 14,
                  dataRowMaxHeight: 15,
                  horizontalMargin: 0,
                  columns: const [
                    DataColumn(
                        label: SizedBox(
                            width: 50, child: Text('name', style: heading))),
                    DataColumn(
                        label: SizedBox(
                            width: 50, child: Text('stat', style: heading))),
                  ],
                  rows: [
                    iob(summary),
                    cob(summary),
                    power(summary),
                    cage(summary),
                    tempBasal(summary),
                    target(summary, settings.unit),
                  ],
                ),
              )),
            ),
          ],
        ),
      );
    });
  }

  DataRow iob(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(
          Text("IOB", style: row),
        ),
        DataCell(
          Text("${summary.state.iob}u", style: row),
        ),
      ],
    );
  }

  DataRow cob(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(
          Text("COB", style: row),
        ),
        DataCell(
          Text("${summary.state.cob}g", style: row),
        ),
      ],
    );
  }

  DataRow power(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(Text("Power", style: row)),
        DataCell(
          Text("${summary.state.battery}%", style: row),
        ),
      ],
    );
  }

  DataRow cage(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(Text("cage", style: row)),
        DataCell(
          Text("${summary.state.cage}h", style: row),
        ),
      ],
    );
  }

  DataRow tempBasal(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(Text("TempBasal", style: row)),
        DataCell(
          Text(summary.lastTempBasal?.description ?? "none", style: row),
        ),
      ],
    );
  }

  DataRow target(Summary summary, Unit unit) {
    var lastTarget = summary.lastTarget;
    lastTarget?.unit = unit;
    return DataRow(
      cells: [
        const DataCell(Text("Target", style: row)),
        DataCell(
          Text(lastTarget?.description ?? "none", style: row),
        ),
      ],
    );
  }
}
