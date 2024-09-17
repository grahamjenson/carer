import 'package:carer/services/themes_service.dart';
import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget with ThemeMixin {
  final String text;

  final double height;
  final double width;
  final TextStyle textStyle;
  final GestureLongPressCallback? onLongPress;

  const ToggleButton(
      {super.key, required this.text, this.height = 40, this.width = 40, this.textStyle = const TextStyle(fontSize: 10), this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onLongPress: onLongPress,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: buildText()),
        ));
  }

  Widget buildText() {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: textStyleWithShadows().merge(textStyle),
    );
  }

  static ToggleButtons selectOne<T>(T value, List<String> titles, List<T> values, Function(T) onSelected) {
    assert(titles.length == values.length);
    return ToggleButtons(
      constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
      renderBorder: true,
      borderRadius: BorderRadius.circular(10),
      borderWidth: 0,
      isSelected: List<bool>.generate(titles.length, (int index) => values[index] == value),
      onPressed: (int index) {
        onSelected(values[index]);
      },
      children: List<ToggleButton>.generate(
        titles.length,
        (int index) => ToggleButton(
          text: titles[index],
        ),
      ),
    );
  }
}

Future<T> alertDialogOfButtons<T>(BuildContext context, String title, List<String> titles, List<T> values) {
  assert(titles.length == values.length);
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
                  constraints: const BoxConstraints(maxHeight: 40, maxWidth: 40),
                  renderBorder: true,
                  borderRadius: BorderRadius.circular(10),
                  borderWidth: 0,
                  isSelected: List<bool>.generate(titles.length, (int index) => false),
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
