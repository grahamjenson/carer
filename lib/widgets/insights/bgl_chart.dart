import 'package:carer/models/clean_sgv.dart';
import 'package:carer/models/sql/constants.dart';
import 'package:carer/models/treatments.dart';
import 'package:carer/models/valueAtTime.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/settings/ui_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TreatmentSpot extends FlSpot {
  final Treatment treatment;
  TreatmentSpot(super.x, super.y, this.treatment);
}

class BGLSpot extends FlSpot {
  final CleanSGV sgv;
  BGLSpot(super.x, super.y, this.sgv);
}

class BasalSpot extends FlSpot {
  final double basal;
  BasalSpot(super.x, super.y, this.basal);
}

class BGLChart extends StatelessWidget with ThemeMixin {
  final basalMultiplier = 18 * 3;

  const BGLChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      int minsAgo = 120;

      List<ValueAtTime> targets = ValueAtTime.lastSixHours.value.where((e) => e.minsAgo < minsAgo).toList();
      List<CleanSGV> sgvs = CleanSGV.last3Hours.value.where((e) => e.minsAgo < minsAgo).toList();
      List<Treatment> lastTreatments = Treatment.lastSixHours.value.where((e) => e.minsAgo < minsAgo).toList();

      // convert the last hours of summary sgvs into flspots
      var bglSpotData = bglSpots(sgvs);
      var (basalSpotData, maxBasal) = basalSpots(targets);
      var (lowTargets, highTargets) = targetSpots(targets);
      var treatments = treatmentsSpots(lastTreatments);

      var bglLineData = LineChartBarData(
        color: tertiaryColor(context),
        spots: bglSpotData,
        barWidth: 1,
        dotData: FlDotData(show: true, getDotPainter: bglDotPainter(tertiaryColor(context))),
      );

      return Window(
        title: "",
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              right: 10,
              top: 5,
            ),
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
        ),
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
    Color sColor = secondaryColor(context);
    Color tColor = tertiaryColor(context);

    return LineChartData(
      rangeAnnotations: rangeAnnotations(pColor.withAlpha(30)),
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
                tColor.dim,
              )),
        ),
      ],
      lineTouchData: lineTouchData(UISettings().unit, tColor),
      betweenBarsData: [
        BetweenBarsData(fromIndex: 0, toIndex: 1, color: pColor.dim.withAlpha(120)),
      ],
    );
  }

  List<FlSpot> treatmentsSpots(List<Treatment> lastTreatments) {
    List<FlSpot> spots = [];

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

      spots.add(TreatmentSpot(-treatment.age.inMinutes.toDouble(), 270, treatment));

      lastTreatment = treatment;
    }

    return spots;
  }

  List<FlSpot> bglSpots(List<CleanSGV> sgvs) {
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
    return SideTitles(
        showTitles: true,
        reservedSize: 17,
        interval: 30,
        getTitlesWidget: (double value, TitleMeta meta) {
          var style = const TextStyle(fontWeight: FontWeight.bold, fontSize: 7, height: 0.5);

          //return Spacer if value is not mod 30
          if (value.toInt() % 30 != 0) {
            return const SizedBox();
          }

          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(Dates.dateAgoShort(Duration(minutes: value.toInt().abs())), style: style),
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

  GetDotPainterCallback bglDotPainter(Color color) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      return FlDotCirclePainter(
        radius: 2,
        color: color,
        strokeColor: color,
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

  GetDotPainterCallback treatmentsDotPainter(Color color) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      if (spot is TreatmentSpot) {
        if (spot.treatment.insulin != 0 && spot.treatment.carbs != 0) {
          return FlTextPainterPainter(
            "${spot.treatment.insulinStr} ${spot.treatment.carbStr}",
            align: flipAlignment(index),
            strokeColor: Colors.black,
            size: 8,
            color: color,
          );
        } else if (spot.treatment.insulin != 0) {
          return FlTextPainterPainter(
            spot.treatment.insulinStr,
            align: flipAlignment(index),
            strokeColor: Colors.black,
            size: 8,
            color: color,
          );
        } else if (spot.treatment.carbs != 0) {
          return FlTextPainterPainter(
            spot.treatment.carbStr,
            align: flipAlignment(index),
            strokeColor: Colors.black,
            size: 8,
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
