import 'dart:math';

import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/care/care_carbs.dart';
import 'package:carer/widgets/care/care_temp_targets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CarePage extends StatelessWidget with ThemeMixin {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        var children = carbButtons(context) + tempTargetButtons(context);
        var itemCount = children.length;

        var columns = 2;
        if (UISettings().orientation == Orientation.landscape) {
          columns = 4;
        }

        final rows = (itemCount / columns).ceil();
        // get Width of the screen
        final screenWidth = MediaQuery.of(context).size.width - 20;
        final screenHeight = MediaQuery.of(context).size.height - 130;
        double ratio = 2;
        if (UISettings().orientation == Orientation.landscape) {
          ratio = 1;
        }
        var itemsWidth = max(min((screenWidth) / columns, screenHeight / rows), 100) * ratio;
        var itemsHeight = itemsWidth / ratio;

        return Scaffold(
          backgroundColor: backgroundColor(context),
          appBar: AppBar(
            title: const Text('Care'),
            actions: [getEditButton(context)],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: (rows * itemsHeight).toDouble(),
              width: (columns * itemsWidth).toDouble(),
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: GridView.count(
                crossAxisCount: columns,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                childAspectRatio: ratio,
                children: children,
              ),
            ),
          ),
        );
      },
      debugLabel: "CarePage",
      dependencies: [UISettings().orientationSignal],
    );
  }

  Widget getEditButton(BuildContext context) {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor(context).dim,
        ),
        child: Text(
          "Edit",
          style: TextStyle(color: accentColor(context), fontSize: 16),
        ),
        onPressed: () {
          GoRouter.of(context).go("/care/edit");
        },
      ),
    );
  }

  List<Widget> carbButtons(BuildContext context) {
    return allCarbs.map((e) {
      return carbsActionTile(context, e);
    }).toList();
  }

  List<Widget> tempTargetButtons(BuildContext context) {
    return allTempTargets.map((e) {
      return tempTargetActionTile(context, e);
    }).toList();
  }

  Widget carbsActionTile(BuildContext context, CarbsSettingsModel e) {
    var buttonStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 20, color: ColorSchemes.primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: const BorderSide(
          color: ColorSchemes.primaryColor,
          width: 2,
        ), // Border color and width
      ),

      padding: const EdgeInsets.all(5), // Remove default padding
    );

    Widget ret = ElevatedButton(
      style: buttonStyle,
      onPressed: e.generateOnPressedFunction(context),
      child: Text("Add ${e.description}", style: const TextStyle(color: ColorSchemes.primaryColor)),
    );

    return Container(
      margin: const EdgeInsets.all(5),
      child: ret,
    );
  }

  Widget tempTargetActionTile(BuildContext context, TempTargetSettingsModel e) {
    var buttonStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 15, color: ColorSchemes.accentColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Square shape
        side: const BorderSide(
          color: ColorSchemes.accentColor,
          width: 2,
        ), // Border color and width
      ),

      padding: const EdgeInsets.all(5), // Remove default padding
    );

    var description = "Set Target\n${e.description}";
    if (e.isCancel) {
      description = e.description;
    }
    Widget ret = ElevatedButton(
      style: buttonStyle,
      onPressed: e.generateOnPressedFunction(context),
      child: Text(description, style: const TextStyle(color: ColorSchemes.accentColor)),
    );

    return Container(
      margin: const EdgeInsets.all(5),
      child: ret,
    );
  }
}
