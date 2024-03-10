import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final IconData? superscriptIcon;

  const ToggleButton(
      {super.key,
      required this.text,
      required this.icon,
      this.superscriptIcon});

  @override
  Widget build(BuildContext context) {
    if (superscriptIcon != null) {
      return SizedBox(
          width: 40,
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                  flex: 1,
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Icon(superscriptIcon, size: 10))),
              Flexible(flex: 6, child: Icon(icon, size: 25)),
              Flexible(
                  flex: 2,
                  child: Text(text,
                      style: const TextStyle(fontSize: 8, height: 0.5))),
            ],
          ));
    }

    return SizedBox(
        width: 50,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(flex: 3, child: Icon(icon, size: 35)),
            Flexible(
                flex: 1,
                child: Text(text,
                    style: const TextStyle(fontSize: 8, height: 0.5))),
          ],
        ));
  }
}
