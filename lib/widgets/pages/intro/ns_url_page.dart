import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
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

  @override
  void initState() {
    super.initState();
    _nsTextController.addListener(() async {
      var (url, token) = SecureSettings().nightscoutURLAndTokenFromString(_nsTextController.text);

      var errMsg = await NSClient().testNSUrlAndToken(url, token);
      if (errMsg != null) {
        setState(() => nightscoutMessage = errMsg);
        setState(() => nightscoutValid = false);
      } else {
        setState(() => nightscoutMessage = "");
        setState(() => nightscoutValid = true);
      }
    });
  }

  @override
  void dispose() {
    _nsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle btnStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(accentColor(context).dim.dim.dim),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(20)),
      textStyle: WidgetStateProperty.all<TextStyle>(
        const TextStyle(
          fontSize: 30,
        ),
      ),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      side: WidgetStateProperty.all<BorderSide>(
        BorderSide(color: accentColor(context).dim.dim, width: 1), // Change border color here
      ),
    );

    VoidCallback? onPressed;
    if (nightscoutValid) {
      onPressed = () {
        SecureSettings().setNSValuesFromURL(_nsTextController.text);
        GoRouter.of(context).go('/display');
      };
    }

    String errMessageString = "";
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
          Divider(
            height: 40,
            thickness: 10,
            color: Colors.blue.dim,
          ),
          MarkdownBody(data: "**URL**: $nsURL \n\n **TOKEN**: $token$errMessageString"),
          Divider(
            height: 40,
            thickness: 10,
            color: Colors.blue.dim,
          ),
          ElevatedButton(
            style: btnStyle,
            onPressed: onPressed,
            child: const Text("Next"),
          ),
          ElevatedButton(
            style: btnStyle,
            onPressed: onPressed = () {
              GoRouter.of(context).go('/display');
            },
            child: const Text("Skip"),
          ),
        ],
      ),
    );
  }
}
