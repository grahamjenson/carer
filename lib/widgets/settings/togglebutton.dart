import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  const ToggleButton({super.key, required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Icon(icon, size: 35),
        Text(text, style: const TextStyle(fontSize: 8, height: 0.5)),
      ],
    ));
  }
}
