import 'dart:async';

import 'package:carer/change_notifiers/settings_cn.dart';
import 'package:carer/change_notifiers/update_cn.dart';
import 'package:carer/models/sgv.dart';
import 'package:carer/widgets/bgl/magarrow.dart';
import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatefulWidget {
  const BGL({super.key});

  @override
  State<BGL> createState() => _BGLState();
}

class _BGLState extends State<BGL> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // This will trigger a rebuild of your widget every second.
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsCN, UpdateCN>(
        builder: (context, settings, summaryCn, child) {
      return FutureBuilder<Widget>(
          future: futureWindow(settings),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            } else {
              return const CircularProgressIndicator();
            }
          });
    });
  }

  Future<Widget> futureWindow(SettingsCN settings) async {
    const loader = Center(child: CircularProgressIndicator());

    var sgv = await SGV.lastSGV();
    if (sgv == null) {
      return loader;
    }
    var unit = settings.unit;

    return AspectRatio(
        aspectRatio: 1.5,
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, -0.9),
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.2,
                child: FittedBox(
                  alignment: const Alignment(0, 0),
                  child: timeAgoText(sgv),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 1,
              child: FittedBox(
                child: Text(sgv.sgvStr(unit),
                    style: const TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            Align(
              alignment: const Alignment(0.4, 0.85),
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 0.2,
                child: Row(children: [
                  Expanded(
                    child: FittedBox(
                      child: Text(
                        await sgv.rate5mWithSign(unit),
                        style: const TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Flexible(
                      child: FractionallySizedBox(
                          heightFactor: 1, child: MagArrow())),
                ]),
              ),
            ),
          ],
        ));
  }

  Widget timeAgoText(SGV delta) {
    if (delta.age.inMinutes == 0) {
      return const Text(
        "now",
        style: TextStyle(
          color: mainColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    var seconds = delta.age.inSeconds % 300;
    var additionalTX = const TextSpan(text: "");
    if ((delta.age.inSeconds > 300 && seconds < 15)) {
      additionalTX = TextSpan(
          text: " (~${seconds}s late)", style: const TextStyle(fontSize: 3));
    }
    return RichText(
        text: TextSpan(
      text: "${delta.age.inMinutes}",
      style: const TextStyle(
        color: mainColor,
        fontWeight: FontWeight.bold,
      ),
      children: [
        const TextSpan(text: "min", style: TextStyle(fontSize: 6)),
        additionalTX,
      ],
    ));
  }
}
