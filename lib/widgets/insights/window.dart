import 'package:carer/services/themes_service.dart';
import 'package:flutter/material.dart';

class Window extends StatelessWidget with ThemeMixin {
  final Widget child;
  final String title;
  Window({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    var mainColor = primaryColor(context);
    return Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            child: Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                  fontSize: 10,
                )),
          ),
          Container(
            height: 1,
            color: mainColor.withAlpha(250), // Color of the bottom line
          ),
          child
        ],
      ),
    );
  }
}
