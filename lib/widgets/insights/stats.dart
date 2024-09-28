import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/properties_data.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/sql/profile.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/prediction_service.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

class Stats extends StatelessWidget with ThemeMixin {
  Stats({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle heading = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: primaryColor(context),
      height: 1,
    );
    TextStyle row = TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: labelSmall(context).color!,
      height: 1,
    );

    TextStyle small = const TextStyle(
      fontSize: 10,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1,
    );

    return AWatch((context) {
      var valuesAtTime = ValueAtTime.lastSixHours.value;
      var currentBasal = 0.0;
      var profileLowTarget = 0;
      var profileHighTarget = 0;
      if (valuesAtTime.isNotEmpty) {
        currentBasal = valuesAtTime.first.basal;
        profileLowTarget = valuesAtTime.first.lowTarget;
        profileHighTarget = valuesAtTime.first.highTarget;
      }

      var iobNow = PropertiesData().iob;
      var cobNow = PropertiesData().cob;
      var cageNow = PropertiesData().cage;
      var powerNow = PropertiesData().battery;
      var charging = PropertiesData().t1dPhoneIsCharging();
      var sageNow = PropertiesData().sage;

      var sgvs = CleanSGV.last3Hours.value;
      var exp2preds = PredictionService().predictionsForReadings;

      return Window(
        title: "Stats",
        child: Expanded(
          child: SingleChildScrollView(
            child: Container(
              alignment: Alignment.center,
              child: DataTable(
                border: TableBorder(
                  verticalInside: BorderSide(color: outlineColor(context)),
                  horizontalInside: const BorderSide(color: Color.fromARGB(0, 0, 0, 0), width: 0.0),
                ),
                columnSpacing: 10,
                dividerThickness: 0.01,
                headingRowHeight: 0,
                dataRowMinHeight: 14,
                dataRowMaxHeight: 23,
                horizontalMargin: 0,
                columns: [
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
                  iob(iobNow, heading, row, small),
                  cob(cobNow, heading, row, small),
                  basal(currentBasal, heading, row, small),
                  target(UISettings().unit, profileLowTarget, profileHighTarget, heading, row, small),
                  currentProfile(heading, row, small),
                  fifteenMinDiff(UISettings().unit, sgvs, heading, row, small),
                  profileValues(heading, row, small),
                  divider(),
                  todaysInRange(heading, row, small),
                  yesterdayInRange(heading, row, small),
                  cage(cageNow, heading, row, small),
                  sage(sageNow, heading, row, small),
                  power(powerNow.toInt(), charging, heading, row, small),
                  divider(),
                  predictions("Forecast", exp2preds, UISettings().unit, heading, row, small),
                ],
              ),
            ),
          ),
        ),
      );
    }, debugLabel: "Stats");
  }

  DataRow divider() {
    var style = const TextStyle(fontSize: 0);
    return DataRow(
      cells: [
        DataCell(Text(" ", style: style)),
        DataCell(Text(" ", style: style)),
      ],
    );
  }

  DataRow profileValues(TextStyle heading, TextStyle row, TextStyle small) {
    ValueAtTime? valueAtTime = ValueAtTime.lastSixHours.value.firstOrNull;
    if (valueAtTime == null) {
      return DataRow(
        cells: [
          DataCell(Text("CR/ISF", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }
    var cr = valueAtTime.cr;
    var isf = valueAtTime.isf;

    return DataRow(
      cells: [
        DataCell(Text("CR/ISF", style: heading)),
        DataCell(
          SmartText(textAlign: TextAlign.center, texts: [
            "$cr",
            "g",
            " | ",
            "$isf",
            "u",
          ], styles: [
            row,
            small,
            row,
            row,
            small,
          ]),
        ),
      ],
    );
  }

  DataRow currentProfile(TextStyle heading, TextStyle row, TextStyle small) {
    var profile = Profile.currentProfile.value;
    var texts = ["none"];
    var styles = [row];

    if (profile != null) {
      texts = ["${profile.percent}", "%"];
      styles = [row, small];

      if (profile.duration != 0) {
        texts = ["${profile.percent}", "% for "];
        styles = [row, small];
        var (daTexts, daStyles) = dateAgoShort(profile.remaining, lessthanString: "<1", heading, row, small);
        texts.addAll(daTexts);
        styles.addAll(daStyles);
      }
    }

    return DataRow(
      cells: [
        DataCell(Text("Profile", style: heading)),
        DataCell(
          SmartText(textAlign: TextAlign.center, texts: texts, styles: styles),
        ),
      ],
    );
  }

  DataRow model(double rmse, TextStyle heading, TextStyle row, TextStyle small) {
    return DataRow(
      cells: [
        DataCell(Text("Model", style: heading)),
        DataCell(
          Text("Linear(${toMax2dp(rmse)})", style: small),
        ),
      ],
    );
  }

  DataRow predictions(String name, List<CleanSGV> preds, Unit unit, TextStyle heading, TextStyle row, TextStyle small) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: heading)),
        DataCell(
          SmartText(texts: [
            "${preds.map(
              (e) => unit.str(e.value),
            )}"
          ], styles: [
            small,
          ]),
        ),
      ],
    );
  }

  DataRow iob(double iob, TextStyle heading, TextStyle row, TextStyle small) {
    iob = toMax2dp(iob);
    return DataRow(
      cells: [
        DataCell(
          Text("IOB", style: heading),
        ),
        DataCell(
          SmartText(textAlign: TextAlign.center, texts: ["$iob", "u"], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow cob(double cob, TextStyle heading, TextStyle row, TextStyle small) {
    cob = toMax2dp(cob);
    return DataRow(
      cells: [
        DataCell(
          Text("COB", style: heading),
        ),
        DataCell(
          SmartText(texts: ["$cob", "g"], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow power(int battery, bool charging, TextStyle heading, TextStyle row, TextStyle small) {
    Widget chargingW = const SizedBox.shrink();

    if (charging) {
      chargingW = Icon(UniconsLine.bolt, color: row.color!, size: row.fontSize);
    }
    return DataRow(
      cells: [
        DataCell(Text("Power", style: heading)),
        DataCell(
          Row(children: [
            SmartText(texts: ["$battery", "%"], styles: [row, small]),
            chargingW,
          ]),
        ),
      ],
    );
  }

  DataRow cage(DateTime cage, TextStyle heading, TextStyle row, TextStyle small) {
    Duration d = DateTime.now().difference(cage);
    return DataRow(
      cells: [
        DataCell(Text("cage", style: heading)),
        DataCell(
          SmartText(texts: ["${d.inDays}", "d"], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow sage(DateTime sage, TextStyle heading, TextStyle row, TextStyle small) {
    Duration d = DateTime.now().difference(sage);
    return DataRow(
      cells: [
        DataCell(Text("sage", style: heading)),
        DataCell(
          SmartText(texts: ["${d.inDays}", "d"], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow basal(profileBasal, TextStyle heading, TextStyle row, TextStyle small) {
    return DataRow(
      cells: [
        DataCell(Text("Basal", style: heading)),
        DataCell(getBasalDescription(profileBasal, null, heading, row, small)),
      ],
    );
  }

  (List<String>, List<TextStyle>) dateAgoShort(Duration diff, TextStyle heading, TextStyle row, TextStyle small, {String lessthanString = "now"}) {
    if (diff.inMinutes == 0) {
      return ([lessthanString], [row]);
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

  SmartText getBasalDescription(double value, Duration? remaining, TextStyle heading, TextStyle row, TextStyle small) {
    var texts = ["${toMax2dp(value)}", "u/h "];
    var styles = [row, small];
    if (remaining != null) {
      var (daTexts, daStyles) = dateAgoShort(remaining, heading, row, small);
      texts.addAll(daTexts);
      styles.addAll(daStyles);
    }
    return SmartText(texts: texts, styles: styles);
  }

  DataRow target(Unit unit, int profileLowTarget, profileHighTarget, TextStyle heading, TextStyle row, TextStyle small) {
    return DataRow(
      cells: [
        DataCell(Text("Target", style: heading)),
        DataCell(
          targetDesciption(profileLowTarget, profileHighTarget, unit, null, heading, row, small),
        ),
      ],
    );
  }

  SmartText targetDesciption(num low, num high, Unit unit, Duration? remaining, TextStyle heading, TextStyle row, TextStyle small) {
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
      var (daTexts, daStyles) = dateAgoShort(remaining, heading, row, small);
      texts.addAll(daTexts);
      styles.addAll(daStyles);
    }

    return SmartText(texts: texts, styles: styles);
  }

  DataRow fifteenMinDiff(Unit unit, List<CleanSGV> bigsgvs, TextStyle heading, TextStyle row, TextStyle small) {
    if (bigsgvs.length < 3) {
      return DataRow(
        cells: [
          DataCell(Text("15m Δ", style: heading)),
          DataCell(
            Text("none", style: row),
          ),
        ],
      );
    }
    var sgvs = bigsgvs.sublist(0, 3);
    var diff = sgvs.first.value - sgvs.last.value;
    return DataRow(
      cells: [
        DataCell(Text("15m Δ", style: heading)),
        DataCell(
          SmartText(texts: [(unit.str(diff)), (unit.name)], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow todaysInRange(TextStyle heading, TextStyle row, TextStyle small) {
    var percent = CleanSGV.todaysPercentage.value;
    if (percent == null || percent.isNaN || percent.isInfinite) {
      percent = 0.0;
    }
    return DataRow(
      cells: [
        DataCell(Text("TIR", style: heading)),
        DataCell(
          SmartText(texts: [percent.toStringAsFixed(0), "%"], styles: [row, small]),
        ),
      ],
    );
  }

  DataRow yesterdayInRange(TextStyle heading, TextStyle row, TextStyle small) {
    var percent = CleanSGV.yesterdaysPercentage.value;
    if (percent == null || percent.isNaN || percent.isInfinite) {
      percent = 0.0;
    }

    return DataRow(
      cells: [
        DataCell(Text("YIR", style: heading)),
        DataCell(
          SmartText(texts: [percent.toStringAsFixed(0), "%"], styles: [row, small]),
        ),
      ],
    );
  }
}
