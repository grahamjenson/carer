import 'package:carer/models/details/info/info_service.dart';
import 'package:carer/services/settings/status_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';

class InfoWidget extends StatelessWidget with ThemeMixin {
  InfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        List<DataRow?> rows = [
          infoRow(context, Info.iob),
          infoRow(context, Info.cob),
          infoRow(context, Info.basal),
          infoRow(context, Info.target),
          infoRow(context, Info.currentProfile),
          infoRow(context, Info.todaysInRange),
          infoRow(context, Info.yesterdayInRange),
        ];

        List<DataRow> filteredRows = rows.whereType<DataRow>().toList();

        return Window(
          child: SingleChildScrollView(
            child: Container(
              alignment: Alignment.center,
              child: DataTable(
                  border: TableBorder(
                    verticalInside: const BorderSide(color: Colors.transparent, width: 0),
                    horizontalInside: BorderSide(color: outlineColor(context), width: 1),
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
                  rows: filteredRows),
            ),
          ),
        );
      },
      debugLabel: "Stats",
      dependencies: StatusSettings().allSignals() + [],
    );
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

  DataRow? infoRow(BuildContext context, Info stat) {
    if (!stat.enabled) {
      return null;
    }

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
      message: stat.tooltip,
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
