import 'dart:math';

import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/care/care_carbs.dart';
import 'package:carer/widgets/care/care_model.dart';
import 'package:carer/widgets/care/care_profiles.dart';
import 'package:carer/widgets/care/care_temp_targets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CarePage extends StatelessWidget with ThemeMixin {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch(
      (context) {
        return Scaffold(
          backgroundColor: backgroundColor(context),
          appBar: AppBar(
            title: const Text('Care'),
            actions: [getEditButton(context)],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                var children = carbButtons(context) + tempTargetButtons(context) + profileSwitchButtons(context);
                var itemCount = children.length;

                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                var columns = 1;
                if (UISettings().orientation == Orientation.landscape) {
                  columns = 4;
                }

                final rows = (itemCount / columns).ceil();

                var itemsHeight = min(max(screenHeight / rows, 50), 100);

                var itemsWidth = max(screenWidth / columns, 100);

                var ratio = itemsWidth / itemsHeight;

                return Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: (rows * itemsHeight).toDouble(),
                    width: (columns * itemsWidth).toDouble(),
                    margin: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
                    child: GridView.count(
                      crossAxisCount: columns,
                      //physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      childAspectRatio: ratio,
                      children: children,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      debugLabel: "CarePage",
      dependencies: [UISettings().orientationSignal] + CareSettings().allSignals(),
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
      return treatmentActionButton(context, e);
    }).toList();
  }

  List<Widget> tempTargetButtons(BuildContext context) {
    return allTempTargets.map((e) {
      return treatmentActionButton(context, e);
    }).toList();
  }

  List<Widget> profileSwitchButtons(BuildContext context) {
    return allProfileSwitches.where((e) => e.getName().isNotEmpty).map((e) {
      return treatmentActionButton(context, e);
    }).toList();
  }

  ButtonStyle buttonStyle(CareModel cm) {
    return ElevatedButton.styleFrom(
      backgroundColor: ColorSchemes.backgroundColor.dim,
      textStyle: TextStyle(fontSize: 20, color: cm.highlightColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Square shape
        side: BorderSide(
          color: ColorSchemes.backgroundColor.bright.bright,
          width: 2,
        ), // Border color and width
      ),
      padding: const EdgeInsets.all(5), // Remove default padding
    );
  }

  Widget treatmentActionButton(BuildContext context, CareModel cm) {
    return Container(
      margin: const EdgeInsets.all(3),
      child: ElevatedButton(
        style: buttonStyle(cm),
        onPressed: cm.generateOnPressedFunction(context),
        child: Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(5),
              child: Icon(cm.icon, size: 30, color: cm.highlightColor),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 5),
                alignment: Alignment.centerLeft,
                child: cm.smartText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
