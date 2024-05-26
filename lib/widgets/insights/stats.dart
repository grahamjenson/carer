import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:clock/clock.dart';
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

    return Consumer2<SettingsCN, UpdateCN>(
        builder: (context, settings, summaryCn, child) {
      var summary = summaryCn.summary;
      return FutureBuilder<Window>(
          future: futureWindow(summary, settings),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Stats snapshot error: ${snapshot.error}");
            }
            if (snapshot.hasData) {
              return snapshot.data!;
            } else {
              return const CircularProgressIndicator();
            }
          });
    });
  }

  Future<Window> futureWindow(Summary summary, SettingsCN settings) async {
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
                  label:
                      SizedBox(width: 50, child: Text('stat', style: heading))),
            ],
            rows: [
              iob(summary),
              cob(summary),
              power(summary),
              cage(summary),
              basal(summary),
              target(summary, settings.unit),
              await fifteenMinDiff(summary, settings.unit),
              await todaysInRange(settings.targetLow, settings.targetHigh),
            ],
          ),
        )),
      ),
    );
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
    var (profileBasal, tempBasal) = summary.basalAtTime(clock.now());
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
        summary.targetAtTime(clock.now());
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

  Future<DataRow> fifteenMinDiff(Summary summary, Unit unit) async {
    var sgvs = await SGV.lastMins(15);
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
    var diff = sgvs.last.value - sgvs.first.value;
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

  Future<DataRow> todaysInRange(int low, int high) async {
    var percent =
        (await SGV.percentInRangeToday(low, high) * 100.0).toStringAsFixed(0);
    // get mills at start of day

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
