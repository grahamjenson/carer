import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

const ts = TextStyle(
  fontSize: 100, // Set the font size to the value you want
  height: 0.8,
);

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow
IconData trendIcon(SGV? delta) {
  if (delta == null) {
    return UniconsLine.question;
  }

  var sgv = delta.sgv;

  if (sgv.abs() < 5) {
    return UniconsLine.arrow_right;
  } else if (sgv.abs() < 9) {
    // diagonal arrows
    if (sgv < 0) {
      return UniconsLine.arrow_down_right;
    }
    return UniconsLine.arrow_up_right;
  } else if (sgv.abs() < 19) {
    // diagonal arrows
    if (sgv < 0) {
      return UniconsLine.arrow_down;
    }
    return UniconsLine.arrow_up;
  } else {
    if (sgv < 0) {
      return UniconsLine.angle_double_down;
    }
    return UniconsLine.angle_double_up;
  }
}

class BGL extends StatelessWidget {
  const BGL({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) => Builder(
              builder: ((context) {
                const loader = Center(child: CircularProgressIndicator());
                if (summaryCn.summary.dateRetrieved == Dates.earliest) {
                  return loader;
                }

                var lastSGV = summaryCn.summary.lastSGV;
                if (lastSGV == null) {
                  return loader;
                }

                return bglLayout(lastSGV, summaryCn, settings);
              }),
            ));
  }

  Widget bglLayout(SGV lastSGV, SummaryCN summaryCn, Settings settings) {
    return Row(children: [
      Expanded(flex: 2, child: bgl(lastSGV.sgvU(settings.unit))),
      Expanded(flex: 1, child: diffPanel(settings, summaryCn))
    ]);
  }

  Widget bgl(double sgv) {
    var lowerTarget = 4;
    var upperTarget = 10;

    return Container(
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        alignment: AlignmentDirectional.centerEnd,
        fit: BoxFit.contain,
        child: Text(
          sgv.toStringAsFixed(1),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 100,
            height: 0.8,
            color: (sgv < lowerTarget || sgv > upperTarget)
                ? Colors.red
                : Colors.green,
          ),
        ),
      ),
    );
  }

  Widget diffPanel(Settings settings, SummaryCN summaryCn) {
    var delta = summaryCn.summary.delta;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 5),
        Expanded(flex: 2, child: deltaV(settings.unit, delta)),
        Expanded(flex: 4, child: trend(delta)),
        Expanded(flex: 2, child: timeSince(Dates.dateAgoShort(delta?.age))),
        const Spacer(flex: 5),
      ],
    );
  }

  Widget trend(SGV? delta) {
    return FittedBox(child: Icon(trendIcon(delta), size: 10));
  }

  Widget deltaV(Unit unit, SGV? delta) {
    if (delta == null) {
      return const FittedBox(
          child: Text(
        "?",
        textAlign: TextAlign.left,
        style: ts,
      ));
    }

    var deltaU = delta.sgvU(unit);
    if (deltaU == 0) {
      return const FittedBox(
          child: Text(
        "0",
        textAlign: TextAlign.left,
        style: ts,
      ));
    } else if (deltaU > 0) {
      return FittedBox(
          child: Text(
        "+${deltaU.toStringAsFixed(1)}",
        textAlign: TextAlign.left,
        style: ts,
      ));
    }

    return FittedBox(
        child: Text(
      deltaU.toStringAsFixed(1),
      textAlign: TextAlign.left,
      style: ts,
    ));
  }

  Widget timeSince(String dateStr) {
    return FittedBox(
        child: Text(
      style: ts,
      dateStr,
    ));
  }
}
