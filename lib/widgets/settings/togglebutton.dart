import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double height;
  final double width;

  const ToggleButton({
    super.key,
    required this.text,
    this.icon,
    this.height = 40,
    this.width = 40,
  });

  @override
  Widget build(BuildContext context) {
    print("fjoisdjfoidsjoifds $height");
    return SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Center(child: buildIcon()),
            Center(child: buildText()),
          ],
        ));
  }

  Widget buildIcon() {
    if (icon != null) {
      return const SizedBox.shrink();
    }
    return Icon(
      icon,
      size: height - 10,
      color: mainColor.withAlpha(50),
    );
  }

  Widget buildText() {
    return Text(text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: height / 4.0,
          shadows: const [
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

Future<T> alertDialogOfButtons<T>(
    BuildContext context, String title, List<String> titles, List<T> values) {
  return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 0.8, fontSize: 16),
            ),
            titlePadding: const EdgeInsets.all(5),
            contentPadding: const EdgeInsets.all(5),
            actionsPadding: const EdgeInsets.all(0),
            content: SizedBox(
              height: 50,
              child: Center(
                child: ToggleButtons(
                  constraints:
                      const BoxConstraints(maxHeight: 40, maxWidth: 40),
                  renderBorder: true,
                  borderRadius: BorderRadius.circular(10),
                  borderWidth: 0,
                  isSelected:
                      List<bool>.generate(titles.length, (int index) => false),
                  onPressed: (int index) {
                    Navigator.of(context).pop(index);
                  },
                  children: List<ToggleButton>.generate(
                    titles.length,
                    (int index) => ToggleButton(
                      text: titles[index],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
          )).then((int? valueFromDialog) {
    if (valueFromDialog == null) {
      return values[0];
    }
    return values[valueFromDialog];
  });
}
