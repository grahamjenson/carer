import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class NSSetupPage extends StatefulWidget {
  const NSSetupPage({super.key});

  @override
  State<NSSetupPage> createState() => _NSSetupPageState();
}

class _NSSetupPageState extends State<NSSetupPage> with ThemeMixin {
  final TextEditingController _nsTextController = TextEditingController();

  String nightscoutMessage = "";
  bool nightscoutValid = false;
  TextStyle activeBtnTextStyle = const TextStyle(fontSize: 30, color: ColorSchemes.primaryColor);
  TextStyle nullBtnTextStyle = TextStyle(fontSize: 30, color: ColorSchemes.primaryColor.dim.dim);

  ButtonStyle activeBtnStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(ColorSchemes.accentColor.dim.dim.dim),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(20)),
    textStyle: WidgetStateProperty.all<TextStyle>(
      const TextStyle(fontSize: 30, color: ColorSchemes.primaryColor),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
    side: WidgetStateProperty.all<BorderSide>(
      BorderSide(color: ColorSchemes.accentColor.dim.dim, width: 1), // Change border color here
    ),
  );

  ButtonStyle nullBtnStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(ColorSchemes.accentColor.dim.dim.dim),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(20)),
    textStyle: WidgetStateProperty.all<TextStyle>(
      TextStyle(fontSize: 30, color: ColorSchemes.primaryColor.dim.dim),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
    side: WidgetStateProperty.all<BorderSide>(
      BorderSide(color: ColorSchemes.accentColor.dim.dim, width: 1), // Change border color here
    ),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    onTestPressed() async {
      var (url, token) = SecureSettings().nightscoutURLAndTokenFromString(_nsTextController.text);

      var (bigErr, errMsg) = await go(NSClient().testNSUrlAndToken(url, token));
      if (bigErr != null) {
        errMsg = bigErr.toString();
      }

      if (errMsg != null) {
        setState(() => nightscoutMessage = "$errMsg");
        setState(() => nightscoutValid = false);
      } else {
        setState(() => nightscoutMessage = "");
        setState(() => nightscoutValid = true);
      }
    }

    VoidCallback? nextPressed;
    var nextBtnStyle = nullBtnStyle;
    var nextBtnTextStyle = nullBtnTextStyle;

    String errMessageString = "";
    if (nightscoutValid) {
      nextPressed = () {
        SecureSettings().setNSValuesFromURL(_nsTextController.text);
        GoRouter.of(context).go('/display');
      };
      nextBtnStyle = activeBtnStyle;
      nextBtnTextStyle = activeBtnTextStyle;
      errMessageString = "Good to go!";
    }

    if (nightscoutMessage.isNotEmpty) {
      errMessageString = "\n\n **Error**: $nightscoutMessage";
    }
    var (nsURL, token) = SecureSettings().nightscoutURLAndTokenFromString(_nsTextController.text);
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const MarkdownBody(data: "# Nightscout Setup\nNightScout URL with Token \n\n e.g. `https://nsurl.com?token=1234567890`"),
          TextField(
            decoration: const InputDecoration(hintText: "NightScout URL"),
            autofocus: true,
            controller: _nsTextController,
          ),
          const Divider(
            height: 10,
            thickness: 10,
            color: Colors.transparent,
          ),
          ElevatedButton(
            style: activeBtnStyle,
            onPressed: onTestPressed,
            child: Text("Test", style: activeBtnTextStyle),
          ),
          MarkdownBody(data: errMessageString),
          Divider(
            height: 40,
            thickness: 10,
            color: Colors.blue.dim,
          ),
          MarkdownBody(data: "**URL**: $nsURL \n\n **TOKEN**: $token"),
          const Divider(
            height: 10,
            thickness: 10,
            color: Colors.transparent,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                style: nextBtnStyle,
                onPressed: nextPressed,
                child: Text("Save & Next", style: nextBtnTextStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
