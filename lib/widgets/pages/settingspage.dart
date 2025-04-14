import 'package:animations/animations.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/settings/about_settings.dart';
import 'package:carer/widgets/settings/debug_settings.dart';
import 'package:carer/widgets/settings/info_settings.dart';
import 'package:carer/widgets/settings/services_settings.dart';
import 'package:carer/widgets/settings/status_settings.dart';
import 'package:carer/widgets/settings/ui_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

enum SettingPageTabs { misc, info, status }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with ThemeMixin {
  var _selectedSegment = SettingPageTabs.misc;

  @override
  Widget build(BuildContext context) {
    var miscPage = SettingsList(
      key: const ValueKey("SettingsPageMisc"),
      sections: [
        ServicesSettingsWidget(),
        const UISettingsWidget(),
        const DebugSettingsWidget(),
        const AboutSettingsWidget(),
      ],
    );

    var infoPage = const SettingsList(
      key: ValueKey("SettingsPageInfo"),
      sections: [
        InfoSettingsWidget(),
      ],
    );

    var statusPage = const SettingsList(
      key: ValueKey("SettingsPageStatus"),
      sections: [
        StatusSettingsWidget(),
      ],
    );

    var child = miscPage;
    switch (_selectedSegment) {
      case SettingPageTabs.misc:
        child = miscPage;
        break;
      case SettingPageTabs.info:
        child = infoPage;
        break;
      case SettingPageTabs.status:
        child = statusPage;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: Colors.black,
      body: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticBackgroundVisibility: false,
          transitionBetweenRoutes: false,
          backgroundColor: Colors.black,
          // This Cupertino segmented control has the enum "Sky" as the type.
          middle: SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<SettingPageTabs>(
              // This represents the currently selected segmented control.
              groupValue: _selectedSegment,
              // Callback that sets the selected segmented control.
              onValueChanged: (SettingPageTabs? value) {
                if (value != null) {
                  setState(() {
                    _selectedSegment = value;
                  });
                }
              },
              children: const <SettingPageTabs, Widget>{
                SettingPageTabs.misc: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Settings', style: TextStyle(color: ColorSchemes.textColor)),
                ),
                SettingPageTabs.info: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Info Bar', style: TextStyle(color: ColorSchemes.textColor)),
                ),
                SettingPageTabs.status: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Status Bar', style: TextStyle(color: ColorSchemes.textColor)),
                ),
              },
            ),
          ),
        ),
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.black,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
