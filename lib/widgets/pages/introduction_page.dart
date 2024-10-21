import 'package:carer/services/themes_service.dart';
import 'package:carer/widgets/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionPage extends StatelessWidget with ThemeMixin {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor(context),
      body: SafeArea(
        child: IntroductionScreen(
          pages: [
            PageViewModel(
              title: "Welcome to Carer",
              body: "Carer is a diabetes management app that helps you manage your diabetes.",
              image: Image.asset("assets/carer_logo.png"),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                bodyTextStyle: TextStyle(fontSize: 20),
              ),
            ),
            PageViewModel(
              title: "Get Started",
              body: "To get started, tap on the 'Settings' button to configure your settings.",
              image: Image.asset("assets/carer_logo.png"),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                bodyTextStyle: TextStyle(fontSize: 20),
              ),
            ),
            PageViewModel(
              title: "Manage Your Diabetes",
              body: "Carer helps you manage your diabetes by providing you with the tools you need to monitor your blood sugar levels.",
              image: Image.asset("assets/carer_logo.png"),
              decoration: const PageDecoration(
                pageColor: Colors.white,
                titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                bodyTextStyle: TextStyle(fontSize: 20),
              ),
            ),
          ],
          onDone: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
          showSkipButton: true,
          skip: const Text("Skip"),
          next: const Text("Next"),
          done: const Text("Done"),
          dotsDecorator: DotsDecorator(
            size: const Size(10.0, 10.0),
            color: Colors.grey,
            activeColor: Colors.blue,
            activeSize: const Size(20.0, 10.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
      ),
    );
  }
}
