import 'package:carer/services/update_service.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/widgets/bar.dart';
import 'package:carer/widgets/home_layout.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
            onRefresh: () async {
              alog("Forcing Update");
              for (var element in UpdateService().updaters) {
                element.forceUpdate();
              }
              // just to see something is happening
              await Future.delayed(const Duration(seconds: 1));
            },
            displacement: 10,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight, maxHeight: constraints.maxHeight),
                child: const HomeLayout(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Bar(),
    );
  }
}
