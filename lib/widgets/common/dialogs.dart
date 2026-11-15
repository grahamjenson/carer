import 'package:carer/services/themes_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Dialogs {
  static Future<bool?> areYouSureDialog(BuildContext context, String title, String content, String confirmText) {
    TextStyle style = const TextStyle(
      color: ColorSchemes.primaryColor, // static so not dim at night
      fontSize: 18,
    );

    TextStyle cancelStyle = const TextStyle(
      color: ColorSchemes.primaryColor, // static so not dim at night
      fontSize: 18,
    );

    Widget cancelButton = TextButton(
      child: Text(
        "Cancel",
        style: cancelStyle,
      ),
      onPressed: () {
        GoRouter? router = GoRouter.maybeOf(context);
        router?.pop(false);
      },
    );
    Widget confirm = TextButton(
      child: Text(
        confirmText,
        style: style,
      ),
      onPressed: () {
        GoRouter? router = GoRouter.maybeOf(context);
        router?.pop(true);
      },
    );

    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [cancelButton, confirm],
          );
        });
  }
}
