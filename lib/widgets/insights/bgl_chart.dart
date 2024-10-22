import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/insights/bgl_chart_painters.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:clock/clock.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

ASignal<int> _chartMinsAgo = ASignal<int>(120, debugLabel: "BGLChartminsAgo");
int get chartHoursAgo => _chartMinsAgo.value ~/ 60;
set chartHoursAgo(int value) => _chartMinsAgo.value = value * 60;

class BGLChart extends StatelessWidget with ThemeMixin {
  final basalMultiplier = 18 * 3;

  const BGLChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      int minsAgo = _chartMinsAgo.value;

      List<ValueAtTime> targets = ValueAtTime.last2Days.value.where((e) => e.minsAgo < minsAgo).toList();
      List<ASGV> sgvs = SGV.last2Days.value.where((e) => e.minsAgo < minsAgo).toList();
      List<Treatment> lastTreatments = Treatment.last2days.value.where((e) => e.minsAgo < minsAgo).toList();

      // convert the last hours of summary sgvs into flspots
      var bglSpotData = bglSpots(sgvs);
      var (basalSpotData, maxBasal) = basalSpots(targets);
      var (lowTargets, highTargets) = targetSpots(targets);
      var (carbSpots, bolusSpots) = treatmentsSpots(lastTreatments);

      var buttonTextStyle = labelLarge(context).copyWith(color: onBackgroundColor(context));
      return Window(
        child: Column(children: [
          Flexible(
              flex: 15,
              child: ToggleButtons(
                  selectedColor: accentColor(context),
                  constraints: const BoxConstraints(maxHeight: 20, minWidth: 53, minHeight: 20),
                  isSelected: [
                    chartHoursAgo == 2,
                    chartHoursAgo == 4,
                    chartHoursAgo == 6,
                    chartHoursAgo == 12,
                    chartHoursAgo == 24,
                  ],
                  onPressed: (int index) {
                    if (index == 0) {
                      chartHoursAgo = 2;
                    } else if (index == 1) {
                      chartHoursAgo = 4;
                    } else if (index == 2) {
                      chartHoursAgo = 6;
                    } else if (index == 3) {
                      chartHoursAgo = 12;
                    } else if (index == 4) {
                      chartHoursAgo = 24;
                    }
                  },
                  children: [
                    Text("2h", style: buttonTextStyle),
                    Text("4h", style: buttonTextStyle),
                    Text("6h", style: buttonTextStyle),
                    Text("12h", style: buttonTextStyle),
                    Text("24h", style: buttonTextStyle),
                  ])),
          Flexible(
            flex: 90,
            child: LineChart(
              buildlineChartData(
                context,
                minsAgo,
                maxBasal,
                bglSpotData,
                basalSpotData,
                lowTargets,
                highTargets,
                carbSpots,
                bolusSpots,
              ),
              duration: Duration.zero,
            ),
          ),
        ]),
      );
    }, debugLabel: "BGLChart");
  }

  LineChartData buildlineChartData(
    BuildContext context,
    int minsAgo,
    double maxBasal,
    List<FlSpot> bglSpotData,
    List<FlSpot> basalSpotData,
    List<FlSpot> lowTargets,
    List<FlSpot> highTargets,
    List<FlSpot> carbTreatmentSpots,
    List<FlSpot> bolusTreatmentSpots,
  ) {
    double maxY = 306;
    double minY = 0;
    double minX = -1 * minsAgo.toDouble(); // mins ago
    double maxX = 0; // now

    Color pColor = accentColor(context);
    Color opColor = backgroundColorShade(context);
    Color tColor = primaryColor(context);

    var bglLineData = LineChartBarData(
      color: primaryColor(context),
      spots: bglSpotData,
      barWidth: 1,
      dotData: FlDotData(show: true, getDotPainter: PainterFunctions().bglDotPainter(context)),
    );

    return LineChartData(
      rangeAnnotations: rangeAnnotations(pColor.withAlpha(45)),
      gridData: gridData(opColor.withAlpha(20)),
      titlesData: titleData(context, maxBasal),
      borderData: borderData(opColor.withAlpha(20)),
      maxX: maxX,
      minX: minX,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        // These are rendered first to last
        LineChartBarData(
          color: pColor.dim,
          spots: lowTargets,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          color: pColor.dim,
          spots: highTargets,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        bglLineData,
        LineChartBarData(
          color: tColor.dim,
          spots: basalSpotData,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: carbTreatmentSpots,
          barWidth: 0,
          dotData: FlDotData(
              show: true,
              getDotPainter: PainterFunctions().treatmentsDotPainter(
                context,
              )),
        ),
        LineChartBarData(
          spots: bolusTreatmentSpots,
          barWidth: 0,
          dotData: FlDotData(
              show: true,
              getDotPainter: PainterFunctions().treatmentsDotPainter(
                context,
              )),
        ),
      ],
      lineTouchData: lineTouchData(context),
      betweenBarsData: [
        BetweenBarsData(fromIndex: 0, toIndex: 1, color: pColor.dim.withAlpha(120)),
      ],
    );
  }

  (List<FlSpot>, List<FlSpot>) treatmentsSpots(List<Treatment> lastTreatments) {
    List<FlSpot> carbSpots = [];
    List<FlSpot> bolusSpots = [];

    // we are going to pain these all at the same height and if they are too close to one another we will decrese height by 10
    Treatment? lastTreatment;
    var diff = 0.0;
    const double change = 20;
    for (var treatment in lastTreatments) {
      if (lastTreatment != null && treatment.age.inMinutes - lastTreatment.age.inMinutes < 12) {
        diff = (diff + change) % (change * 2);
      } else {
        diff = 0;
      }

      if (treatment.isBolus) {
        bolusSpots.add(TreatmentSpot(-treatment.age.inMinutes.toDouble(), 265, treatment));
      } else {
        carbSpots.add(TreatmentSpot(-treatment.age.inMinutes.toDouble(), 280, treatment));
      }

      lastTreatment = treatment;
    }

    return (carbSpots, bolusSpots);
  }

  List<FlSpot> bglSpots(List<ASGV> sgvs) {
    List<FlSpot> spots = [];
    for (var i = 0; i < sgvs.length; i++) {
      var sgv = sgvs[i];
      spots.add(BGLSpot(-sgv.age.inMinutes.toDouble(), sgv.value.toDouble(), sgv));
    }
    return spots;
  }

  (List<FlSpot>, double) basalSpots(List<ValueAtTime> targets) {
    List<BasalSpot> spots = [];
    // Check the basal at every minute
    for (var t in targets) {
      spots.add(BasalSpot(-t.age.inMinutes.toDouble(), t.basal, t.basal));
    }

    if (spots.isEmpty) {
      return (spots, 1.0);
    }
    // Max basal from the list
    double maxBasal = spots.reduce((value, element) => value.y > element.y ? value : element).y;

    // we are going to normilize the list of basals to the max basal so all values are betwen 0 and 1, then multiplied by size
    if (maxBasal == 0) {
      spots = spots.map((e) => BasalSpot(e.x, 0, 0)).toList();
    } else {
      spots = spots.map((e) => BasalSpot(e.x, (e.y / maxBasal) * basalMultiplier, e.basal)).toList();
    }

    return (spots, maxBasal);
  }

  (List<FlSpot>, List<FlSpot>) targetSpots(List<ValueAtTime> targets) {
    List<FlSpot> lowTargets = [];
    List<FlSpot> highTargets = [];

    for (var t in targets) {
      lowTargets.add(FlSpot(-t.age.inMinutes.toDouble(), t.lowTarget.toDouble()));
      highTargets.add(FlSpot(-t.age.inMinutes.toDouble(), t.highTarget.toDouble()));
    }

    return (lowTargets, highTargets);
  }

  LineTouchData lineTouchData(BuildContext context) {
    var color = accentColor(context);
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        // kill all tootips
        getTooltipItems: (touchedSpots) => touchedSpots.map((e) => null).toList(),
      ),
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
        return indicators.map(
          (int index) {
            if (barData.spots.length <= index) {
              return null;
            }
            var spot = barData.spots[index];
            if (spot is BGLSpot) {
              var line = FlLine(
                color: color.dim.dim,
                strokeWidth: 1,
                dashArray: [2, 4],
              );
              return TouchedSpotIndicatorData(
                line,
                FlDotData(show: true, getDotPainter: PainterFunctions().highlightPainer(context)),
              );
            }

            if (spot is BasalSpot) {
              var line = const FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
              return TouchedSpotIndicatorData(
                line,
                FlDotData(show: true, getDotPainter: PainterFunctions().highlightPainer(context)),
              );
            }

            if (spot is TreatmentSpot) {
              var line = const FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
              return TouchedSpotIndicatorData(
                line,
                FlDotData(show: true, getDotPainter: PainterFunctions().highlightPainer(context)),
              );
            }

            return null;
          },
        ).toList();
      },
    );
  }

  FlBorderData borderData(Color color) {
    return FlBorderData(
      show: true,
      border: Border.all(color: color, width: 1),
    );
  }

  FlTitlesData titleData(BuildContext context, double maxBasal) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: rightTitleWidgets(context, maxBasal)),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: bottomTitleWidgets(context),
      ),
      leftTitles: AxisTitles(sideTitles: leftTitleWidgets(context)),
    );
  }

  FlGridData gridData(Color color) {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 36,
      verticalInterval: 10,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: color,
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: color,
          strokeWidth: 1,
        );
      },
    );
  }

  RangeAnnotations rangeAnnotations(Color color) {
    return RangeAnnotations(
      horizontalRangeAnnotations: [
        HorizontalRangeAnnotation(
          y1: TargetSettings().highUrgent.toDouble(),
          y2: TargetSettings().lowUrgent.toDouble(),
          color: color.dim,
        ),
        HorizontalRangeAnnotation(
          y1: TargetSettings().highTarget.toDouble(),
          y2: TargetSettings().lowTarget.toDouble(),
          color: color,
        ),
      ],
    );
  }

  SideTitles bottomTitleWidgets(BuildContext context) {
    bool showTime = false;
    int showTimeHours = 1;
    if (chartHoursAgo >= 6) {
      showTime = true;

      if (_chartMinsAgo.value > 1000) {
        showTimeHours = 2;
      }
    }
    return SideTitles(
        showTitles: true,
        reservedSize: 17,
        interval: 1,
        getTitlesWidget: (double value, TitleMeta meta) {
          var style = TextStyle(fontWeight: FontWeight.bold, fontSize: 7, height: 0.5, color: onBackgroundColor(context));

          var duration = Duration(minutes: value.toInt().abs());
          var date = clock.now().subtract(duration);

          //return Spacer if value is not mod 30 or on the hour if time
          if (showTime && (date.minute != 0 || date.hour % showTimeHours != 0)) {
            return const SizedBox.shrink();
          } else if (!showTime && (value.toInt() % 30 != 0)) {
            return const SizedBox.shrink();
          }

          var str = Dates.dateAgoShort(duration);
          if (showTime) {
            str = Dates.dateShort(date);
          }

          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(str, style: style),
          );
        });
  }

  SideTitles rightTitleWidgets(BuildContext context, double maxBasal) {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 19,
      getTitlesWidget: (double value, TitleMeta meta) {
        var style = TextStyle(fontWeight: FontWeight.bold, fontSize: 6, height: 0.5, color: onBackgroundColor(context));

        bool drawTitle = (value == basalMultiplier.toDouble() || value == basalMultiplier.toDouble() / 2);

        if (maxBasal == 0) {
          drawTitle = value == 0;
        }

        if (drawTitle) {
          var x = value / basalMultiplier * maxBasal;
          x = (x * 100).round() / 100; // round to 2dp
          return Text("${x}u", style: style, textAlign: TextAlign.right);
        }

        return const SizedBox();
      },
    );
  }

  SideTitles leftTitleWidgets(BuildContext context) {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 18,
      getTitlesWidget: (double value, TitleMeta meta) {
        var style = TextStyle(fontWeight: FontWeight.bold, fontSize: 6, height: 0.5, color: onBackgroundColor(context));

        if (value.toInt() == TargetSettings().highUrgent ||
            value.toInt() == TargetSettings().lowUrgent ||
            value.toInt() == TargetSettings().highTarget ||
            value.toInt() == TargetSettings().lowTarget) {
          return Text(UISettings().unit.str(value), style: style, textAlign: TextAlign.right);
        }
        return const SizedBox();
      },
    );
  }
}
