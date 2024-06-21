import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
import 'package:carer/models/constants.dart';
import 'package:carer/models/profile.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/models/state_data.dart';
import 'package:carer/predictors/sgv_predictors.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

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
    print("oisdhfiudshf");
    return Consumer2<SettingsCN, UpdateCN>(
        builder: (context, settings, _, child) {
      print("124124124");
      return FutureBuilder<Window>(
          future: futureWindow(settings),
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

  Future<Window> futureWindow(SettingsCN settings) async {
    var stateData = await StateData.instance;

    Exp2Predictor exp2predictor = Exp2Predictor();
    await exp2predictor.init();

    var profileBasal = await Profile.basalAtTime(clock.now());

    var (profileLowTarget, profileHighTarget) =
        await Profile.targetAtTime(clock.now());

    var sgvs = await SGV.lastMins(15);

    var exp2preds = exp2predictor.predictNextHour();
    var ypercent = (await SGV.percentInRangeYesterday(
                settings.targetLow, settings.targetHigh) *
            100.0)
        .toStringAsFixed(0);

    var tpercent = (await SGV.percentInRangeToday(
                settings.targetLow, settings.targetHigh) *
            100.0)
        .toStringAsFixed(0);

    return Window(
      title: "Stats",
      child: Expanded(
        child: SingleChildScrollView(
            child: Container(
          alignment: Alignment.center,
          child: Watch((_) {
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
                DataColumn(
                    label: SizedBox(
                        width: 50, child: Text('stat', style: heading))),
              ],
              rows: [
                iob(stateData),
                cob(stateData),
                power(stateData),
                cage(stateData),
                basal(profileBasal),
                target(SettingNames.unit.signal.value, profileLowTarget,
                    profileHighTarget),
                fifteenMinDiff(SettingNames.unit.signal.value, sgvs),
                todaysInRange(tpercent),
                yesterdayInRange(ypercent),
                predictions("Exp2", exp2preds, SettingNames.unit.signal.value),
              ],
            );
          }),
        )),
      ),
    );
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

  DataRow iob(StateData stateData) {
    return DataRow(
      cells: [
        const DataCell(
          Text("IOB", style: heading),
        ),
        DataCell(
          SmartText(
              textAlign: TextAlign.center,
              texts: ["${stateData.iob()}", "u"],
              styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cob(StateData stateData) {
    return DataRow(
      cells: [
        const DataCell(
          Text("COB", style: heading),
        ),
        DataCell(
          SmartText(
              texts: ["${stateData.cob()}", "g"], styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow power(StateData stateData) {
    return DataRow(
      cells: [
        const DataCell(Text("Power", style: heading)),
        DataCell(
          SmartText(
              texts: ["${stateData.battery()}", "%"],
              styles: const [row, small]),
        ),
      ],
    );
  }

  DataRow cage(StateData stateData) {
    return DataRow(
      cells: [
        const DataCell(Text("cage", style: heading)),
        DataCell(
          SmartText(
              texts: ["${stateData.cage()}", "h"], styles: const [row, small]),
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

  DataRow fifteenMinDiff(Unit unit, List<SGV> sgvs) {
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

  DataRow todaysInRange(String percent) {
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

  DataRow yesterdayInRange(String percent) {
    // get mills at start of day

    return DataRow(
      cells: [
        const DataCell(Text("YIR", style: heading)),
        DataCell(
          SmartText(texts: [percent, "%"], styles: const [row, small]),
        ),
      ],
    );
  }
}
