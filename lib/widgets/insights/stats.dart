import 'package:carer/models/models.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});
  static const TextStyle row =
      TextStyle(color: mainColor, fontSize: 14, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    const heading =
        TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      if (!settings.uiSettings.showStats) {
        return const SizedBox.shrink();
      }
      var summary = summaryCn.summary;
      return Window(
        title: "Stats",
        child: Expanded(
          child: SingleChildScrollView(
              child: Container(
            alignment: Alignment.center,
            child: DataTable(
              columnSpacing: 5,
              dividerThickness: 0.01,
              headingRowHeight: 0,
              dataRowMinHeight: 14,
              dataRowMaxHeight: 18,
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
                basal(summary),
                target(summary, settings.unit),
                fifteenMinDiff(summary, settings.unit),
                todaysInRange(summary, settings.targetLow, settings.targetHigh),
              ],
            ),
          )),
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

  DataRow basal(Summary summary) {
    var (profileBasal, tempBasal) = summary.basalAtTime(DateTime.now());
    // Something is very wrong if there is no profile basal, so just checking that
    if (profileBasal == null) {
      return const DataRow(
        cells: [
          DataCell(Text("Basal", style: row)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }

    if (tempBasal != null) {
      return DataRow(
        cells: [
          const DataCell(Text("Basal*", style: row)),
          DataCell(
            Text(getBasalDescription(tempBasal.absolute, tempBasal.remaining),
                style: row),
          ),
        ],
      );
    }

    return DataRow(
      cells: [
        const DataCell(Text("Basal", style: row)),
        DataCell(
          Text(getBasalDescription(profileBasal.value, null), style: row),
        ),
      ],
    );
  }

  String getBasalDescription(double value, Duration? remaining) {
    var str = "${value.toStringAsFixed(2)}u";
    if (remaining != null) {
      str += " ${Dates.dateAgoShort(remaining, hours: false)}";
    }
    return str;
  }

  DataRow target(Summary summary, Unit unit) {
    var (profileLowTarget, profileHighTarget, tempTarget) =
        summary.targetAtTime(DateTime.now());
    // Something is very wrong if there is no profile target, so just checking that
    if (profileLowTarget == null || profileHighTarget == null) {
      return const DataRow(
        cells: [
          DataCell(Text("Target", style: row)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }

    if (tempTarget != null) {
      return DataRow(
        cells: [
          const DataCell(Text("Target*", style: row)),
          DataCell(
            Text(
                targetDesciption(tempTarget.targetBottom, tempTarget.targetTop,
                    unit, tempTarget.remaining),
                style: row),
          ),
        ],
      );
    }

    return DataRow(
      cells: [
        const DataCell(Text("Target", style: row)),
        DataCell(
          Text(
              targetDesciption(
                  profileLowTarget.value, profileHighTarget.value, unit, null),
              style: row),
        ),
      ],
    );
  }

  String targetDesciption(num low, num high, Unit unit, Duration? remaining) {
    var str = "${unit.str(low)}${unit.name}";
    if (low != high) {
      str = "${unit.str(low)}-${unit.str(high)}${unit.name}";
    }
    if (remaining != null) {
      str += " ${Dates.dateAgoShort(remaining, hours: false)}";
    }
    return str;
  }

  DataRow fifteenMinDiff(Summary summary, Unit unit) {
    var sgvs = summary.sgvs.lastMins(15);
    if (sgvs.isEmpty) {
      return const DataRow(
        cells: [
          DataCell(Text("15min diff", style: row)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }
    var diff = summary.lastSGV!.sgv - sgvs.first.sgv;
    return DataRow(
      cells: [
        const DataCell(Text("15min diff", style: row)),
        DataCell(
          Text("${unit.str(diff)}${unit.name}", style: row),
        ),
      ],
    );
  }

  DataRow todaysInRange(Summary summary, int low, int high) {
    // TODO summary does not include this.

    var sgvsTodayInRange = summary.sgvs.sgvs
        .where((s) => s.sgv >= low && s.sgv <= high)
        // Checks if mills is today
        .toList()
        .length;

    // Total readings today is mins in Today / 5

    var total = summary.sgvs.sgvs.length;
    var percent = ((sgvsTodayInRange / total) * 100).toStringAsFixed(0);

    return DataRow(
      cells: [
        const DataCell(Text("% in range", style: row)),
        DataCell(
          Text("$percent%", style: row),
        ),
      ],
    );
  }
}
