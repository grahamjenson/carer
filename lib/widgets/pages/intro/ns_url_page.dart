import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/settings/services/nightscout_service_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NSSetupPage extends StatelessWidget with ThemeMixin {
  const NSSetupPage({super.key});

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

    return AWatch(
      (context) {
        VoidCallback? nextPressed;
        if (SecureSettings().nightscoutURL != null) {
          nextPressed = () async {
            GoRouter.of(context).go("/display");
          };
        }
        return SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Expanded(child: NightScoutServiceSettings()),
              const Divider(
                height: 10,
                thickness: 10,
                color: Colors.transparent,
              ),
              ElevatedButton(
                style: btnStyle,
                onPressed: nextPressed,
                child: const Text("Next"),
              ),
              const Divider(
                height: 10,
                thickness: 10,
                color: Colors.transparent,
              ),
            ],
          ),
        );
      },
      debugLabel: "NSSetupPage",
      dependencies: SecureSettings().allSignals(),
    );
  }
}
