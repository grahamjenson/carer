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
        var children = [
          const Expanded(child: FittedBox(child: CareCarbs())),
          const Expanded(child: FittedBox(child: CareTempTargets())),
        ];

        Widget body = const SizedBox.shrink();
        if (UISettings().orientation == Orientation.landscape) {
          body = Row(
            children: children,
          );
        } else {
          body = Column(
            children: children,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Care'),
            actions: [getEditButton(context)],
          ),
          body: body,
        );
      },
      debugLabel: "CarePageWidget",
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
}
