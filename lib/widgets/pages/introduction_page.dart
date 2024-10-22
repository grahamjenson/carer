import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/strings.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionPage extends StatelessWidget with ThemeMixin {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final introKey = GlobalKey<IntroductionScreenState>();
    bool acceptedTermsAndConditions = false;
    bool acceptedPrivacyPolicy = false;

    ButtonStyle acceptButtonStyl = ButtonStyle(
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
        child: IntroductionScreen(
          key: introKey,
          isProgressTap: false,
          pages: [
            PageViewModel(
              title: "Welcome to Carer",
              image: Image.asset("assets/carer_logo.png"),
              bodyWidget: const MarkdownBody(data: "Carer is a diabetes management app that helps you monitor Type 1 Diabetes"),
              footer: ElevatedButton(
                style: acceptButtonStyl,
                onPressed: () {
                  introKey.currentState?.next();
                },
                child: const Text("Next"),
              ),
              decoration: const PageDecoration(
                imageFlex: 5,
                bodyFlex: 5,
                footerFlex: 2,
                safeArea: 0,
              ),
            ),
            PageViewModel(
              title: "Terms And Conditions",
              bodyWidget: Column(children: [
                SingleChildScrollView(child: MarkdownBody(data: StringAssets().termsAndConditions)),
                ElevatedButton(
                  style: acceptButtonStyl,
                  child: const Text("Accept"),
                  onPressed: () {
                    acceptedTermsAndConditions = true;
                    introKey.currentState?.next();
                  },
                ),
              ]),
              decoration: const PageDecoration(
                imageFlex: 1,
                bodyFlex: 5,
                footerFlex: 2,
                safeArea: 0,
              ),
            ),
            PageViewModel(
              title: "Privacy Policy",
              bodyWidget: Column(
                children: [
                  MarkdownBody(data: StringAssets().privacyPolicy),
                  ElevatedButton(
                    style: acceptButtonStyl,
                    onPressed: () {
                      acceptedPrivacyPolicy = true;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    child: const Text("Accept"),
                  ),
                ],
              ),
            ),
          ],
          canProgress: (page) {
            bool ret = false;
            if (page == 0) {
              // Can always progress from the first page
              ret = true;
            } else if (page == 1) {
              // must accept T&C to progress
              ret = acceptedTermsAndConditions;
            } else if (page == 2) {
              // must accept PP to progress to main app
              ret = acceptedPrivacyPolicy && acceptedTermsAndConditions;
            }

            return ret;
          },
          showNextButton: false,
          showDoneButton: false,
          showBackButton: true,
          back: const Text("Back"),
          dotsDecorator: DotsDecorator(
            color: primaryColor(context),
            activeColor: accentColor(context),
          ),
        ),
      ),
    );
  }
}
