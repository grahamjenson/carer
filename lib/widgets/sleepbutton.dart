import 'package:flutter/material.dart';

class SleepButton extends StatelessWidget {
  ///To make button more customizable add your child widget
  final Widget? child;

  ///Sets the radius of corners of a button.
  final double radius;

  ///Use it to define a height and width of
  final double height;
  final double width;

  ///Use it to define a color of
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightedColor;
  final Color buttonColor;

  ///Change it to gave a label on a widget of your choice.
  final Widget? label;

  ///Gives a alignment to a slider icon.
  final Widget? icon;
  final Future<bool?> Function() action;

  ///The offset threshold the item has to be dragged in order to be considered
  ///dismissed e.g. if it is 0.4, then the item has to be dragged
  /// at least 40% towards one direction to be considered dismissed
  final double dismissThresholds;

  const SleepButton({
    super.key,
    required this.action,
    this.radius = 100,
    this.child,
    this.height = 70,
    this.width = 270,
    this.backgroundColor = const Color(0xffe0e0e0),
    this.baseColor = Colors.black87,
    this.buttonColor = Colors.white,
    this.highlightedColor = Colors.white,
    this.label,
    this.icon,
    this.dismissThresholds = .75,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: backgroundColor, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: <Widget>[
          Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.startToEnd,
            dismissThresholds: {DismissDirection.startToEnd: dismissThresholds},
            confirmDismiss: (_) async {
              bool result;
              try {
                result = (await action()) ?? true;
              } catch (e) {
                result = false;
              }

              ///break the action
              if (!result) return false;

              return true;
            },
            child: Container(
              width: width - height,
              height: height,
              alignment: Alignment.centerLeft,
              child: child ??
                  Container(
                    height: height,
                    width: height,
                    decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(radius)),
                    child: Center(child: icon),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
