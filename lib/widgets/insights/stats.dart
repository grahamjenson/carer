import 'package:carer/models/models.dart';
import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});

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
              border: const TableBorder(
                verticalInside: BorderSide(color: mainColor),
              ),
              columnSpacing: 10,
              dividerThickness: 0.01,
              headingRowHeight: 0,
              dataRowMinHeight: 14,
              dataRowMaxHeight: 20,
              horizontalMargin: 0,
              columns: const [
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 50,
                    child: Text('name', style: heading),
                  ),
                ),
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
          Text("IOB", style: heading),
        ),
        DataCell(
          SmartText(
              textAlign: TextAlign.center,
              texts: ["${summary.state.iob}", "u"],
              styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cob(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(
          Text("COB", style: heading),
        ),
        DataCell(
          SmartText(
              texts: ["${summary.state.cob}", "g"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow power(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(Text("Power", style: heading)),
        DataCell(
          SmartText(
              texts: ["${summary.state.battery}", "%"],
              styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cage(Summary summary) {
    return DataRow(
      cells: [
        const DataCell(Text("cage", style: heading)),
        DataCell(
          SmartText(
              texts: ["${summary.state.cage}", "h"],
              styles: const [row, small]),
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
          DataCell(Text("Basal", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }

    if (tempBasal != null) {
      return DataRow(
        cells: [
          const DataCell(Text("Basal*", style: heading)),
          DataCell(
            getBasalDescription(tempBasal.absolute, tempBasal.remaining),
          ),
        ],
      );
    }

    return DataRow(
      cells: [
        const DataCell(Text("Basal", style: heading)),
        DataCell(getBasalDescription(profileBasal.value, null)),
      ],
    );
  }

  (List<String>, List<TextStyle>) dateAgoShort(Duration diff) {
    if (diff.inMinutes == 0) {
      return (const ["now"], const [row]);
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
    return (texts, styles);
  }

  SmartText getBasalDescription(double value, Duration? remaining) {
    var texts = ["${toMax2dp(value)}", "u/h "];
    var styles = [row, small];
    if (remaining != null) {
      var (daTexts, daStyles) = dateAgoShort(remaining);
      texts.addAll(daTexts);
      styles.addAll(daStyles);
    }
    return SmartText(texts: texts, styles: styles);
  }

  DataRow target(Summary summary, Unit unit) {
    var (profileLowTarget, profileHighTarget, tempTarget) =
        summary.targetAtTime(DateTime.now());
    // Something is very wrong if there is no profile target, so just checking that
    if (profileLowTarget == null || profileHighTarget == null) {
      return const DataRow(
        cells: [
          DataCell(Text("Target", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }

    if (tempTarget != null) {
      return DataRow(
        cells: [
          const DataCell(Text("Target*", style: heading)),
          DataCell(
            targetDesciption(tempTarget.targetBottom, tempTarget.targetTop,
                unit, tempTarget.remaining),
          ),
        ],
      );
    }

    return DataRow(
      cells: [
        const DataCell(Text("Target", style: heading)),
        DataCell(
          targetDesciption(
              profileLowTarget.value, profileHighTarget.value, unit, null),
        ),
      ],
    );
  }

  SmartText targetDesciption(
      num low, num high, Unit unit, Duration? remaining) {
    List<String> texts = [];
    List<TextStyle> styles = [];
    if (low == high) {
      texts.add(unit.str(low));
      styles.add(row);
    } else {
      texts.add(unit.str(low));
      styles.add(row);
      texts.add("-");
      styles.add(small);
      texts.add(unit.str(high));
      styles.add(row);
    }

    texts.add(unit.name);
    styles.add(small);

    if (remaining != null) {
      var (daTexts, daStyles) = dateAgoShort(remaining);
      texts.addAll(daTexts);
      styles.addAll(daStyles);
    }

    return SmartText(texts: texts, styles: styles);
  }

  DataRow fifteenMinDiff(Summary summary, Unit unit) {
    var sgvs = summary.sgvs.lastMins(15);
    if (sgvs.isEmpty) {
      return const DataRow(
        cells: [
          DataCell(Text("15m Δ", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }
    var diff = summary.lastSGV!.sgv - sgvs.first.sgv;
    return DataRow(
      cells: [
        const DataCell(Text("15m Δ", style: heading)),
        DataCell(
          SmartText(
              texts: [(unit.str(diff)), (unit.name)],
              styles: const [row, small]),
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
        const DataCell(Text("TIR", style: heading)),
        DataCell(
          SmartText(texts: [percent, "%"], styles: const [row, small]),
        ),
      ],
    );
  }
}
