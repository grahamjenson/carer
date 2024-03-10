import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final String text;
  final IconData icon;

  const ToggleButton({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Center(
                child: Icon(
              icon,
              size: 30,
              color: mainColor.withAlpha(50),
            )),
            Center(child: buildText()),
          ],
        ));
  }

  Widget buildText() {
    return Text(text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          shadows: [
            Shadow(
                // bottomLeft
                offset: Offset(-1, -1),
                color: Colors.black),
            Shadow(
                // bottomRight
                offset: Offset(1, -1),
                color: Colors.black),
            Shadow(
                // topRight
                offset: Offset(1, 1),
                color: Colors.black),
            Shadow(
                // topLeft
                offset: Offset(-1, 1),
                color: Colors.black),
          ],
        ));
  }
}
