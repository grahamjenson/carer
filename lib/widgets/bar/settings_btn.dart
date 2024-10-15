import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:flutter/material.dart';

class SettingsBtn extends StatelessWidget with ThemeMixin {
  const SettingsBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      highlightColor: Colors.white,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(backgroundColorShade(context).bright),
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.settings,
        color: accentColor(context),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      },
    );
  }
}
