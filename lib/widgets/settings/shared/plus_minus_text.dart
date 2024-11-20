import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/shared/target_range_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlusMinusText extends StatefulWidget with ThemeMixin {
  final GetStr getStr;
  final FromStr fromStr;
  final Getter getValue;

  final Setter setValue;
  final List<ASignal> dependencies;
  final bool signed;

  const PlusMinusText({
    super.key,
    required this.getStr,
    required this.fromStr,
    required this.getValue,
    required this.setValue,
    required this.dependencies,
    this.signed = false,
  });

  @override
  State<PlusMinusText> createState() => _PlusMinusTextState();
}

class _PlusMinusTextState extends State<PlusMinusText> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.getStr(widget.getValue());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      // https://medium.com/@gabrieloranekwu/number-input-on-flutter-textfields-the-right-way-06441f7b5550
      _controller.text = widget.getStr(widget.getValue());

      var regex = widget.signed ? r'[-+]?[0-9.]?' : r'[0-9.]?';
      return Container(
        alignment: Alignment.center,
        width: 50,
        height: 30,
        child: TextField(
          controller: _controller,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(regex)),
            SinglePeriodEnforcer(),
          ],
          style: const TextStyle(
            fontSize: 12,
            height: 0.8,
            color: ColorSchemes.primaryColor,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: widget.signed),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          onEditingComplete: () => setValue(),
          onTapOutside: (event) => setValue(),
        ),
      );
    }, debugLabel: "PlusMinusText", dependencies: widget.dependencies);
  }

  setValue() {
    FocusScope.of(context).unfocus();
    double? value = widget.fromStr(_controller.text);
    if (value != null) {
      widget.setValue(value);
      _controller.text = widget.getStr(widget.getValue());
    }
  }
}

class SinglePeriodEnforcer extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    // Allow only one period
    if ('.'.allMatches(newText).length <= 1) {
      return newValue;
    }
    return oldValue;
  }
}
