import 'package:carer/models/details/stats/stats_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class Stats extends StatelessWidget with ThemeMixin {
  Stats({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      return Window(
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
              columns: const [
                DataColumn(numeric: true, label: SizedBox(width: 25)),
                DataColumn(label: SizedBox(width: 50)),
              ],
              rows: [
                statsRow(context, Stat.iob),
                statsRow(context, Stat.cob),
                statsRow(context, Stat.basal),
                statsRow(context, Stat.target),
                statsRow(context, Stat.currentProfile),
                divider(),
                statsRow(context, Stat.todaysInRange),
                statsRow(context, Stat.yesterdayInRange),
              ],
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

  DataRow statsRow(BuildContext context, Stat stat) {
    TextStyle heading = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      color: accentColor(context),
      height: 1,
    );

    TextStyle row = TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: onBackgroundColor(context),
      height: 1,
    );

    TextStyle small = TextStyle(
      fontSize: 10,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1,
      color: onBackgroundColor(context).dim,
    );

    var (texts, styles) = stat.status(context, row, small);
    Widget statIcon = Tooltip(
      message: stat.title,
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(stat.icon, size: 20, color: stat.highlight ? primaryColor(context) : accentColor(context)),
    );
    return DataRow(
      cells: [
        DataCell(statIcon),
        DataCell(
          SmartText(textAlign: TextAlign.center, texts: texts, styles: styles),
        ),
      ],
    );
  }
}
