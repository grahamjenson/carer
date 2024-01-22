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
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Container(
                      color: const Color.fromARGB(255, 0, 0, 255),
                      child: FittedBox(
                          fit: BoxFit.cover,
                          child: Text(
                            '${lastSGV.sgvMmolL}',
                          ))),
                  Column(children: [
                    Text(' ${lastSGV.dateAgo}'),
                    Text(' ${lastSGV.dateAgo}'),
                    Text(' ${lastSGV.dateAgo}'),
                  ]),
                ]));
          }),
        ));
  }
}
