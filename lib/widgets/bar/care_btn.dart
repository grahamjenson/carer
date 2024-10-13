import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/pages/care_page.dart';
import 'package:flutter/material.dart';

class CareBtn extends StatelessWidget with ThemeMixin {
  const CareBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      highlightColor: Colors.white,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(backgroundColorShade(context)),
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.back_hand,
        color: accentColor(context),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CarePage()),
        );
      },
    );
  }
}
