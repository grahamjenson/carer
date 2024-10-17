import 'package:flutter/material.dart';

class Dialogs {
  static Future<bool?> areYouSureDialog(BuildContext context, String title, String content, String confirmText) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );
    Widget confirm = TextButton(
      child: Text(confirmText),
      onPressed: () {
        Navigator.of(context).pop(true);
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
