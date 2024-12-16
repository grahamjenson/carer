import 'package:carer/models/flow_data.dart';
import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/pages/pages.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();

  static bool needsOnboarding() {
    return FlowData().agreedTermsOfService == null || FlowData().agreedPrivacyPolicy == null || !SecureSettings().nightscoutURLAndTokenSet();
  }
}

class _IntroductionPageState extends State<IntroductionPage> with ThemeMixin {
  final IntroPageController _pageController = IntroPageController();
  final TextEditingController _nsTextController = TextEditingController();
  final ASignal<String> nightscoutMessage = ASignal("", debugLabel: "NightScoutMessage");
  final ASignal<bool> nightscoutValid = ASignal(false, debugLabel: "NightScoutValid");

  @override
  void initState() {
    super.initState();
    _nsTextController.addListener(() async {
      var (url, token) = SecureSettings().nightscoutURLAndTokenFromString(_nsTextController.text);

      var errMsg = await NSClient().testNSUrlAndToken(url, token);
      if (errMsg != null) {
        nightscoutMessage.value = errMsg;
        nightscoutValid.value = false;
      } else {
        nightscoutMessage.value = "";
        nightscoutValid.value = true;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

    // But of a hack, but there are two lists, one of the pages and the other functions that allow the pages to progress
    // You should not be able to get into the app without agreeing to the terms of service and privacy policy
    // And nothing will work without the nightscout URL so making sure that is setup is important

    // If T&C or Privacy policy change will ask to re-accept
    // Nightscot should be set on first run
    List<Widget> pages = [_getWelcomePage(btnStyle)];
    List<AllowPageChangeFn> allowPageChange = [() => true];

    if (FlowData().agreedTermsOfService == null) {
      pages.add(_getTermsOfServicePage(btnStyle, pages.length + 1));
      allowPageChange.add(() => FlowData().agreedTermsOfService != null);
    }

    if (FlowData().agreedPrivacyPolicy == null) {
      pages.add(_getPrivacyPolicyPage(btnStyle, pages.length + 1));
      allowPageChange.add(() => FlowData().agreedPrivacyPolicy != null);
    }

    if (!SecureSettings().nightscoutURLAndTokenSet()) {
      pages.add(_getNightScoutURLTokenPage(btnStyle, pages.length + 1));
      //allowPageChange.add(() => SecureSettings().nightscoutURLAndTokenSet());
    }

    pages.add(_getFinalPage(btnStyle));
    allowPageChange.add(() => true);
    _pageController.allowPageChangeFns = allowPageChange;

    return Scaffold(
      backgroundColor: backgroundColor(context),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
        ),
      ),
    );
  }

  Widget _getWelcomePage(ButtonStyle btnStyle) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Expanded(flex: 10, child: Image.asset("assets/carer_logo.png")),
          const Flexible(flex: 4, child: MarkdownBody(data: "Carer is a diabetes management app that helps you monitor Type 1 Diabetes")),
          Flexible(
            flex: 4,
            child: ElevatedButton(
              style: btnStyle,
              onPressed: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTermsOfServicePage(ButtonStyle btnStyle, int nextpage) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          children: [
            MarkdownBody(data: StringAssets().termsOfService),
            ElevatedButton(
              style: btnStyle,
              onPressed: () {
                FlowData().agreedTermsOfService = clock.now();

                if (_pageController.hasClients) {
                  _pageController.animateToNextPage();
                }
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPrivacyPolicyPage(ButtonStyle btnStyle, int nextpage) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SingleChildScrollView(child: MarkdownBody(data: StringAssets().privacyPolicy)),
            ElevatedButton(
              style: btnStyle,
              onPressed: () {
                FlowData().agreedPrivacyPolicy = clock.now();
                if (_pageController.hasClients) {
                  _pageController.animateToNextPage();
                }
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getNightScoutURLTokenPage(ButtonStyle btnStyle, int nextpage) {
    return AWatch(
      (context) {
        VoidCallback? onPressed;
        if (nightscoutValid.value) {
          onPressed = () {
            SecureSettings().setNSValuesFromURL(_nsTextController.text);
            if (_pageController.hasClients) {
              _pageController.animateToNextPage();
            }
          };
        }

        String errMessageString = "";
        if (nightscoutMessage.value.isNotEmpty) {
          errMessageString = "\n\n **Error**: ${nightscoutMessage.value}";
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
                  if (_pageController.hasClients) {
                    _pageController.animateToNextPage();
                  }
                },
                child: const Text("Skip"),
              ),
            ],
          ),
        );
      },
      debugLabel: "NightScoutIntroPage",
      dependencies: SecureSettings().allSignals(),
    );
  }

  Widget _getFinalPage(ButtonStyle btnStyle) {
    // TODO about info, dontate into...
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const MarkdownBody(data: "Thank you for using Carer\n**THIS IS STILL BETA SOFTWARE"),
          ElevatedButton(
            style: btnStyle,
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                Pages.home.route,
              );
            },
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < 0) {
      _pageController.animateToNextPage();
    } else if (details.primaryDelta! > 0 && _pageController.page! > 0.0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
}

typedef AllowPageChangeFn = bool Function();

class IntroPageController extends PageController {
  IntroPageController() : super();

  List<AllowPageChangeFn> allowPageChangeFns = [];

  Future<void> animateToNextPage() {
    return animateToPage(page!.toInt() + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    // Must pass all tests up until the page that is being animated to
    if (!allowPageChange(page)) {
      return Future.value();
    }

    return super.animateToPage(page, duration: duration, curve: curve);
  }

  @override
  void jumpToPage(int page) {
    if (!allowPageChange(page)) {
      return;
    }
    super.jumpToPage(page);
  }

  bool allowPageChange(int pageTo) {
    for (AllowPageChangeFn e in allowPageChangeFns.sublist(0, pageTo)) {
      if (!e()) {
        return false;
      }
    }

    return true;
  }
}
