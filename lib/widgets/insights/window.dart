import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class Window extends StatelessWidget {
  final Widget child;
  final String title;
  const Window({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: mainColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: mainColor,
            ),
            child: Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 10,
                )),
          ),
          child
        ],
      ),
    );
  }
}
