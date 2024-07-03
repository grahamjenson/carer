import 'package:carer/models/constants.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/settings.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class Stats extends StatelessWidget {
  const Stats({super.key});

  static const heading = TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 10);

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
    return AWatch((context) {
      try {
        var valuesAtTime = ValueAtTime.lastSixHours().value!;
        var currentBasal = 0.0;
        var profileLowTarget = 0;
        var profileHighTarget = 0;
        if (valuesAtTime.isNotEmpty) {
          currentBasal = valuesAtTime.first.basal;
          profileLowTarget = valuesAtTime.first.lowTarget;
          profileHighTarget = valuesAtTime.first.highTarget;
        }

        var iobNow = StateData().iob();
        var cobNow = StateData().cob();
        var cageNow = StateData().cage();
        var powerNow = StateData().battery();
        var sgvs = SGV.last3Hours().value!;
        var exp2preds = PredictionService().predictions;

        if (sgvs.isNotEmpty) {
          var minsAgo = sgvs.first.minsAgo;
          var first = 5 - minsAgo;
          exp2preds = exp2preds.where((e) => [5 - minsAgo, first, first + 5, first + 10, first + 15].contains(e.minsFromNow)).toList();
        } else {
          exp2preds = exp2preds.where((e) => [5, 10, 15, 20].contains(e.minsFromNow)).toList();
        }

        return Window(
          title: "Stats",
          child: Expanded(
            child: SingleChildScrollView(
                child: Container(
              alignment: Alignment.center,
              child: AWatch((_) {
                return DataTable(
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
                    DataColumn(label: SizedBox(width: 50, child: Text('stat', style: heading))),
                  ],
                  rows: [
                    iob(iobNow),
                    cob(cobNow),
                    power(powerNow),
                    cage(cageNow),
                    basal(currentBasal),
                    target(Settings().unit, profileLowTarget, profileHighTarget),
                    fifteenMinDiff(Settings().unit, sgvs),
                    todaysInRange(),
                    yesterdayInRange(),
                    predictions("Exp2", exp2preds, Settings().unit),
                  ],
                );
              }),
            )),
          ),
        );
      } catch (e, s) {
        print("Error in Stats: $e");
        print("Stack in Stats: $s");
        return const SizedBox();
      }
    });
  }

  DataRow model(double rmse) {
    return DataRow(
      cells: [
        const DataCell(Text("Model", style: heading)),
        DataCell(
          Text("Linear(${toMax2dp(rmse)})", style: small),
        ),
      ],
    );
  }

  DataRow predictions(String name, List<SGV> preds, Unit unit) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: heading)),
        DataCell(
          SmartText(texts: [
            "${preds.map(
              (e) => unit.str(e.value),
            )}"
          ], styles: const [
            small,
          ]),
        ),
      ],
    );
  }

  DataRow iob(double iob) {
    return DataRow(
      cells: [
        const DataCell(
          Text("IOB", style: heading),
        ),
        DataCell(
          SmartText(textAlign: TextAlign.center, texts: ["$iob", "u"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cob(double cob) {
    return DataRow(
      cells: [
        const DataCell(
          Text("COB", style: heading),
        ),
        DataCell(
          SmartText(texts: ["$cob", "g"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow power(double battery) {
    return DataRow(
      cells: [
        const DataCell(Text("Power", style: heading)),
        DataCell(
          SmartText(texts: ["$battery", "%"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cage(double cage) {
    return DataRow(
      cells: [
        const DataCell(Text("cage", style: heading)),
        DataCell(
          SmartText(texts: ["$cage", "h"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow basal(profileBasal) {
    return DataRow(
      cells: [
        const DataCell(Text("Basal", style: heading)),
        DataCell(getBasalDescription(profileBasal, null)),
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

  DataRow target(Unit unit, int profileLowTarget, profileHighTarget) {
    return DataRow(
      cells: [
        const DataCell(Text("Target", style: heading)),
        DataCell(
          targetDesciption(profileLowTarget, profileHighTarget, unit, null),
        ),
      ],
    );
  }

  SmartText targetDesciption(num low, num high, Unit unit, Duration? remaining) {
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

  DataRow fifteenMinDiff(Unit unit, List<SGV> bigsgvs) {
    if (bigsgvs.length < 3) {
      return const DataRow(
        cells: [
          DataCell(Text("15m Δ", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }
    var sgvs = bigsgvs.sublist(0, 3);
    var diff = sgvs.last.value - sgvs.first.value;
    return DataRow(
      cells: [
        const DataCell(Text("15m Δ", style: heading)),
        DataCell(
          SmartText(texts: [(unit.str(diff)), (unit.name)], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow todaysInRange() {
    var percent = SGV.todaysPercentage().value;
    if (percent == null || percent.isNaN || percent.isInfinite) {
      percent = 0.0;
    }
    return DataRow(
      cells: [
        const DataCell(Text("TIR", style: heading)),
        DataCell(
          SmartText(texts: [percent.toStringAsFixed(0), "%"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow yesterdayInRange() {
    var percent = SGV.yesterdaysPercentage().value;
    if (percent == null || percent.isNaN || percent.isInfinite) {
      percent = 0.0;
    }

    return DataRow(
      cells: [
        const DataCell(Text("YIR", style: heading)),
        DataCell(
          SmartText(texts: [percent.toStringAsFixed(0), "%"], styles: const [row, small]),
        ),
      ],
    );
  }
}
