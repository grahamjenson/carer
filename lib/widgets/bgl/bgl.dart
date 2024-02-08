import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/animations.dart';
import 'package:carer/widgets/bgl/diff.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/math.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

//copied from https://xdrip.readthedocs.io/en/latest/use/mainUI/#trend-arrow

class BGL extends StatefulWidget {
  const BGL({super.key});

  @override
  State<BGL> createState() => _BGLState();
}

class _BGLState extends State<BGL> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> heartBeat;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    heartBeat = heartBeatTS().animate(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      const loader = Center(child: CircularProgressIndicator());
      if (summaryCn.summary.dateRetrieved == Dates.earliest) {
        return loader;
      }

      var lastSGV = summaryCn.summary.lastSGV;
      if (lastSGV == null) {
        return loader;
      }

      return bglLayout(lastSGV, summaryCn, settings);
    });
  }

  Widget bglLayout(SGV lastSGV, SummaryCN summaryCn, Settings settings) {
    return Row(children: [
      Expanded(flex: 2, child: bgl(lastSGV, settings)),
      const Expanded(flex: 1, child: DiffWidget())
    ]);
  }

  Widget bgl(SGV sgv, Settings settings) {
    var unit = settings.unit;
    var (target, proportion) = settings.targetRange(sgv.sgv);

    var color = Colours.targetColor(target, proportion);

    return Container(
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        alignment: AlignmentDirectional.centerEnd,
        fit: BoxFit.contain,
        child: Text(
          sgv.sgvStr(unit),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 100,
            height: 0.8,
            color: color,
          ),
        ),
      ),
    );
  }
}
