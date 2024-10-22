import 'package:carer/models/flow_data.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> with ThemeMixin {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = IntroPageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    return Scaffold(
      backgroundColor: backgroundColor(context),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _getWelcomePage(btnStyle),
              _getTermsAndConditionsPage(btnStyle),
              _getPrivacyPolicyPage(btnStyle),
            ],
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

  Widget _getTermsAndConditionsPage(ButtonStyle btnStyle) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          children: [
            MarkdownBody(data: StringAssets().termsAndConditions),
            ElevatedButton(
              style: btnStyle,
              onPressed: () {
                FlowData().agreedTermsAndConditions = clock.now();

                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPrivacyPolicyPage(ButtonStyle btnStyle) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          SingleChildScrollView(child: MarkdownBody(data: StringAssets().privacyPolicy)),
          ElevatedButton(
            style: btnStyle,
            onPressed: () {
              FlowData().agreedPrivacyPolicy = clock.now();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < 0) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (details.primaryDelta! > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
}

allowPageChange(int currentPage, int nextPage) {
  if (currentPage == 0) {
    return true;
  }

  if (currentPage == 1 && nextPage == 2) {
    return FlowData().agreedTermsAndConditions != null;
  }

  if (currentPage == 2 && nextPage == 3) {
    return FlowData().agreedPrivacyPolicy != null;
  }
  return true;
}

class IntroPageController extends PageController {
  IntroPageController() : super();

  @override
  Future<void> animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
  }) {
    if (!allowPageChange(this.page!.round(), page)) {
      return Future.value();
    }
    return super.animateToPage(page, duration: duration, curve: curve);
  }

  @override
  void jumpToPage(int page) {
    if (!allowPageChange(this.page!.round(), page)) {
      return;
    }
    super.jumpToPage(page);
  }
}
