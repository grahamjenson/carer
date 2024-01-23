import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BGL extends StatelessWidget {
  final Summary summary;

  const BGL({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        color: const Color.fromARGB(255, 0, 0, 0),
        alignment: Alignment.center,
        child: Builder(
          builder: ((context) {
            if (summary.dateRetrieved == Dates.earliest) {
              return const CircularProgressIndicator();
            }

            var lastSGV = summary.lastSGV;
            if (lastSGV == null) {
              return const CircularProgressIndicator();
            }

            return Center(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              bgl(lastSGV.sgvMmolL),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                delta(summary.delta()),
                trend(summary.trendIcon()),
                timeSince(lastSGV.dateAgo),
              ]),
            ]));
          }),
        ));
  }

  Widget bgl(double sgv) {
    return Container(
        width: 100,
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              '$sgv',
            )));
  }

  Widget trend(IconData icon) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(fit: BoxFit.cover, child: Icon(icon)));
  }

  Widget delta(double delta) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              '$delta',
            )));
  }

  Widget timeSince(String dateStr) {
    return Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: FittedBox(
            fit: BoxFit.cover,
            child: Text(
              dateStr,
            )));
  }
}
