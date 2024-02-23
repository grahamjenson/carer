import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
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
                  rows: [iob(summaryCn), cob(summaryCn), power(summaryCn)],
                ),
              )),
            ),
          ],
        ),
      );
    });
  }

  DataRow iob(summaryCn) {
    return DataRow(
      cells: [
        const DataCell(
          Text("IOB", style: row),
        ),
        DataCell(
          Text("${summaryCn.summary.state.iob}u", style: row),
        ),
      ],
    );
  }

  DataRow cob(summaryCn) {
    return DataRow(
      cells: [
        const DataCell(
          Text("COB", style: row),
        ),
        DataCell(
          Text("${summaryCn.summary.state.cob}g", style: row),
        ),
      ],
    );
  }

  DataRow power(summaryCn) {
    return DataRow(
      cells: [
        const DataCell(Text("Power", style: row)),
        DataCell(
          Text("${summaryCn.summary.state.battery}%", style: row),
        ),
      ],
    );
  }

  //   Text('IOB ${summaryCn.summary.state.iob}'),
  // Text('COB ${summaryCn.summary.state.cob}'),
  // Text('Power ${summaryCn.summary.state.battery}'),
}
