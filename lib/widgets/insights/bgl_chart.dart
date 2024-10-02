import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:clock/clock.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TreatmentSpot extends FlSpot {
  final TreatmentGroup treatment;
  TreatmentSpot(super.x, super.y, this.treatment);
}

class BGLSpot extends FlSpot {
  final ASGV sgv;
  BGLSpot(super.x, super.y, this.sgv);
}

class BasalSpot extends FlSpot {
  final double basal;
  BasalSpot(super.x, super.y, this.basal);
}

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
      var windowSize = 5;
      if (chartHoursAgo > 6) {
        windowSize = 30;
      }
      if (chartHoursAgo > 12) {
        windowSize = 120;
      }
      if (chartHoursAgo > 15) {
        windowSize = 240;
      }

      List<ValueAtTime> targets = ValueAtTime.last2Days.value.where((e) => e.minsAgo < minsAgo).toList();
      List<ASGV> sgvs = SGV.last2Days.value.where((e) => e.minsAgo < minsAgo).toList();
      List<TreatmentGroup> lastTreatments = TreatmentList.last2days.value.getWindows(windowSize).where((e) => e.minsAgo < minsAgo).toList();

      // convert the last hours of summary sgvs into flspots
      var bglSpotData = bglSpots(sgvs);
      var (basalSpotData, maxBasal) = basalSpots(targets);
      var (lowTargets, highTargets) = targetSpots(targets);
      var treatments = treatmentsSpots(lastTreatments);

      var bglLineData = LineChartBarData(
        color: tertiaryColor(context),
        spots: bglSpotData,
        barWidth: 1,
        dotData: FlDotData(show: true, getDotPainter: bglDotPainter(tertiaryColor(context), secondaryColor(context))),
      );

      return Window(
        child: Column(children: [
          Flexible(
              flex: 15,
              child: ToggleButtons(
                  selectedColor: primaryColor(context),
                  constraints: const BoxConstraints(maxHeight: 20, maxWidth: 60, minWidth: 40, minHeight: 20),
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
                    Text("2h", style: labelLarge(context)),
                    Text("4h", style: labelLarge(context)),
                    Text("6h", style: labelLarge(context)),
                    Text("12h", style: labelLarge(context)),
                    Text("24h", style: labelLarge(context)),
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
                treatments,
                bglLineData,
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
    List<FlSpot> treatments,
    LineChartBarData bglLineData,
  ) {
    double maxY = 306;
    double minY = 0;
    double minX = -1 * minsAgo.toDouble(); // mins ago
    double maxX = 0; // now

    Color pColor = primaryColor(context);
    Color opColor = onPrimaryColor(context);
    Color tColor = tertiaryColor(context);

    return LineChartData(
      rangeAnnotations: rangeAnnotations(pColor.withAlpha(45)),
      gridData: gridData(opColor.withAlpha(20)),
      titlesData: titleData(maxBasal),
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
          spots: treatments,
          barWidth: 0,
          dotData: FlDotData(
              show: true,
              getDotPainter: treatmentsDotPainter(
                tColor,
              )),
        ),
      ],
      lineTouchData: lineTouchData(UISettings().unit, tColor),
      betweenBarsData: [
        BetweenBarsData(fromIndex: 0, toIndex: 1, color: pColor.dim.withAlpha(120)),
      ],
    );
  }

  List<FlSpot> treatmentsSpots(List<TreatmentGroup> lastTreatments) {
    List<FlSpot> spots = [];

    // we are going to pain these all at the same height and if they are too close to one another we will decrese height by 10
    TreatmentGroup? lastTreatment;
    var diff = 0.0;
    const double change = 20;
    for (var treatment in lastTreatments) {
      if (lastTreatment != null && treatment.age.inMinutes - lastTreatment.age.inMinutes < 12) {
        diff = (diff + change) % (change * 2);
      } else {
        diff = 0;
      }

      spots.add(TreatmentSpot(-treatment.age.inMinutes.toDouble(), 270, treatment));

      lastTreatment = treatment;
    }

    return spots;
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

  LineTouchData lineTouchData(Unit unit, Color color) {
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
                FlDotData(show: true, getDotPainter: bglHighlightPainter(unit, color)),
              );
            }

            if (spot is BasalSpot) {
              var line = const FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
              return TouchedSpotIndicatorData(
                line,
                FlDotData(show: true, getDotPainter: bglHighlightPainter(unit, color)),
              );
            }

            if (spot is TreatmentSpot) {
              var line = const FlLine(
                color: Colors.transparent,
                strokeWidth: 0,
              );
              return TouchedSpotIndicatorData(
                line,
                FlDotData(show: true, getDotPainter: bglHighlightPainter(unit, color)),
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

  FlTitlesData titleData(double maxBasal) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: rightTitleWidgets(maxBasal)),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: bottomTitleWidgets(),
      ),
      leftTitles: AxisTitles(sideTitles: leftTitleWidgets()),
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

  SideTitles bottomTitleWidgets() {
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
          var style = const TextStyle(fontWeight: FontWeight.bold, fontSize: 7, height: 0.5);

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

  SideTitles rightTitleWidgets(double maxBasal) {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 19,
      getTitlesWidget: (double value, TitleMeta meta) {
        var style = const TextStyle(fontWeight: FontWeight.bold, fontSize: 6, height: 0.5);

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

  SideTitles leftTitleWidgets() {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 18,
      getTitlesWidget: (double value, TitleMeta meta) {
        var style = const TextStyle(fontWeight: FontWeight.bold, fontSize: 6, height: 0.5);

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

  GetDotPainterCallback bglDotPainter(Color color, Color outOfRangeColor) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      BGLSpot bglspot = spot as BGLSpot;
      var useColor = color;
      var useStrokeColor = color;
      var useStokeWidth = 0.0;
      var useRadius = 2.0;
      if (!bglspot.sgv.isNormal) {
        useColor = outOfRangeColor;
        useRadius = 2.5;
        useStokeWidth = 1.0;
        useStrokeColor = color;
      }
      return FlDotCirclePainter(
        radius: useRadius,
        color: useColor,
        strokeColor: useStrokeColor,
        strokeWidth: useStokeWidth,
      );
    };
  }

  GetDotPainterCallback bglHighlightPainter(Unit unit, Color color) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      if (spot is BGLSpot) {
        return FlTextPainterPainter(
          spot.sgv.sgvStr(unit),
          strokeColor: Colors.black,
          size: 12,
          color: color,
          align: Alignment.topCenter,
        );
      }

      if (spot is BasalSpot) {
        return FlTextPainterPainter(
          "${toMax2dp(spot.basal)}",
          strokeColor: Colors.black,
          size: 8,
          color: color,
          align: Alignment.topCenter,
        );
      }

      if (spot is TreatmentSpot) {
        return treatmentsDotPainter(color, size: 2)(
          spot,
          xPercentage,
          bar,
          index,
        );
      }
      return FlDotCirclePainter(
        radius: 0,
        color: color,
        strokeColor: color,
      );
    };
  }

  Alignment flipAlignment(int index) {
    if (index % 2 == 0) {
      return Alignment.topCenter;
    }
    return Alignment.bottomCenter;
  }

  GetDotPainterCallback treatmentsDotPainter(
    Color color, {
    double size = 1,
  }) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index,
    ) {
      if (spot is TreatmentSpot) {
        if (spot.treatment.isSMBsOnly) {
          return FlTextPainterPainter(
            spot.treatment.treatmentStr,
            align: flipAlignment(index),
            strokeColor: Colors.black,
            size: 8 * size,
            color: Colors.blue,
          );
        } else {
          return FlTextPainterPainter(
            spot.treatment.treatmentStr,
            align: flipAlignment(index),
            strokeColor: Colors.black,
            size: 8 * size,
            color: color,
          );
        }
      }
      return FlDotCirclePainter(
        radius: 0,
        color: color,
        strokeColor: color,
      );
    };
  }
}

/// This class is an implementation of a [FlDotPainter] that draws Text on a canvas
class FlTextPainterPainter extends FlDotPainter with ThemeMixin {
  late FlDotCirclePainter circle;

  /// The color of the square is determined determined by [color],
  /// [size] determines the size of the square.
  /// You can have a stroke line around the square,
  /// by setting the thickness with [strokeWidth],
  /// and you can change the color of of the stroke with [strokeColor].
  FlTextPainterPainter(
    this.text, {
    this.color = Colors.green,
    this.size = 4.0,
    this.strokeColor = const Color.fromRGBO(76, 175, 80, 1),
    this.strokeWidth = 1.0,
    this.align = Alignment.bottomCenter,
  }) {
    circle = FlDotCirclePainter(
      radius: 2,
      color: color,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

  final Alignment align;

  /// The fill color to use for the square
  final Color color;
  final String text;

  /// Customizes the size of the square
  double size;

  /// The stroke color to use for the square
  Color strokeColor;

  /// The stroke width to use for the square
  double strokeWidth;

  TextStyle get style {
    return TextStyle(
      fontSize: size,
      height: 0.6,
      fontWeight: FontWeight.w700,
      color: color,
    ).merge(shadows(
      color: strokeColor,
      width: strokeWidth,
    ));
  }

  /// Implementation of the parent class to draw the square
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    circle.draw(canvas, spot, offsetInCanvas);

    // Create a TextSpan
    var span = TextSpan(
      text: text,
      style: style,
    );

    // Create a TextPainter
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Layout the TextPainter
    painter.layout();
    var centeredOffset = offsetInCanvas;
    switch (align) {
      case Alignment.bottomCenter:
        centeredOffset = offsetInCanvas.translate(
          -painter.width / 2,
          -painter.height / 2 + painter.height + 3,
        );
        break;
      case Alignment.topCenter:
        centeredOffset = offsetInCanvas.translate(
          -painter.width / 2,
          -painter.height / 2 - painter.height - 3,
        );
        break;
    }

    // Draw the TextSpan on the canvas
    painter.paint(canvas, centeredOffset);
  }

  /// Implementation of the parent class to get the size of the square
  @override
  Size getSize(FlSpot spot) {
    return Size(size, size);
  }

  @override
  Color get mainColor => color;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        color,
        size,
        strokeColor,
        strokeWidth,
      ];

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is! FlDotSquarePainter || b is! FlDotSquarePainter) {
      return b;
    }
    return b;
  }
}
