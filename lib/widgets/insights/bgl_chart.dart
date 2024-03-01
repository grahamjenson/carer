import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:carer/widgets/insights/window.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TreatmentSpot extends FlSpot {
  final SummaryTreatment treatment;
  TreatmentSpot(super.x, super.y, this.treatment);
}

const TextStyle touchedTextStyle = TextStyle(
    fontSize: 10,
    height: 0.6,
    fontWeight: FontWeight.w700,
    color: mainColor,
    shadows: [
      Shadow(
          // bottomLeft
          offset: Offset(-1.5, -1.5),
          color: Colors.black),
      Shadow(
          // bottomRight
          offset: Offset(1.5, -1.5),
          color: Colors.black),
      Shadow(
          // topRight
          offset: Offset(1.5, 1.5),
          color: Colors.black),
      Shadow(
          // topLeft
          offset: Offset(-1.5, 1.5),
          color: Colors.black),
    ]);

class BGLChart extends StatelessWidget {
  final basalMultiplier = 18 * 3;

  const BGLChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      int minsAgo = 125;
      // Breaking down the objects
      Summary summary = summaryCn.summary;

      double maxY = settings.urgentHigh + 36;
      double minY = 0;
      double minX = -1 * minsAgo.toDouble(); // mins ago
      double maxX = 0; // now

      // convert the last hours of summary sgvs into flspots
      var bglSpotData = bglSpots(summary, minsAgo);
      var (basalSpotData, maxBasal) = basalSpots(summary, minsAgo);
      var (lowTargets, highTargets) = targetSpots(summary, minsAgo);
      var treatments = treatmentsSpots(summary, minsAgo);

      var lineChartData = LineChartData(
        rangeAnnotations: rangeAnnotations(settings),
        gridData: gridData(),
        titlesData: titleData(settings, maxBasal),
        borderData: borderData(),
        maxX: maxX,
        minX: minX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            color: mainColor,
            spots: bglSpotData,
            barWidth: 2,
            dotData: FlDotData(show: true, getDotPainter: bglDotPainter),
          ),
          LineChartBarData(
            color: mainColor,
            spots: basalSpotData,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: treatments,
            barWidth: 0,
            dotData: FlDotData(show: true, getDotPainter: treatmentsDotPainter),
          ),
          LineChartBarData(
            color: mainColor.withAlpha(140),
            spots: lowTargets,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            color: mainColor.withAlpha(140),
            spots: highTargets,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: lineTouchData(settings),
        betweenBarsData: [
          BetweenBarsData(
              fromIndex: 3, toIndex: 4, color: mainColor.withAlpha(60)),
        ],
      );

      return Window(
        title: "Chart",
        child: Expanded(
            child: Padding(
                padding: const EdgeInsets.only(
                  right: 10,
                  top: 5,
                ),
                child: LineChart(
                  lineChartData,
                  duration: Duration.zero,
                ))),
      );
    });
  }

  List<FlSpot> treatmentsSpots(Summary summary, int minsAgo) {
    List<FlSpot> spots = [];
    var lastTreatments = summary.treatments.summarizedTreatments(minsAgo, 5);

    // we are going to pain these all at the same height and if they are too close to one another we will decrese height by 10
    //SummaryTreatment lastTreatment
    for (var treatment in lastTreatments) {
      spots.add(
          TreatmentSpot(-treatment.age.inMinutes.toDouble(), 260, treatment));
    }

    return spots;
  }

  List<FlSpot> bglSpots(Summary summary, int minsAgo) {
    List<SGV> sgvs = summary.sgvs.lastMins(minsAgo);
    List<FlSpot> spots = [];
    for (var i = 0; i < sgvs.length; i++) {
      var sgv = sgvs[i];
      spots.add(FlSpot(-sgv.age.inMinutes.toDouble(), sgv.sgv.toDouble()));
    }
    return spots;
  }

  (List<FlSpot>, double) basalSpots(Summary summary, int minsAgo) {
    List<FlSpot> spots = [];
    // Check the basal at every minute
    for (int i = 0; i < minsAgo; i++) {
      var (basal, tempbasal) =
          summary.basalAtTime(DateTime.now().subtract(Duration(minutes: i)));
      if (tempbasal != null) {
        spots.add(FlSpot(-i.toDouble(), tempbasal.absolute));
      } else if (basal != null) {
        spots.add(FlSpot(-i.toDouble(), basal.value));
      }
    }
    if (spots.isEmpty) {
      return (spots, 1);
    }
    // Max basal from the list
    double maxBasal = spots
        .reduce((value, element) => value.y > element.y ? value : element)
        .y;

    // we are going to normilize the list of basals to the max basal so all values are betwen 0 and 1, then multiplied by size
    if (maxBasal == 0) {
      spots = spots.map((e) => FlSpot(e.x, 0)).toList();
    } else {
      spots = spots
          .map((e) => FlSpot(e.x, (e.y / maxBasal) * basalMultiplier))
          .toList();
    }

    return (spots, maxBasal);
  }

  (List<FlSpot>, List<FlSpot>) targetSpots(Summary summary, int minsAgo) {
    List<FlSpot> lowTargets = [];
    List<FlSpot> highTargets = [];
    for (int i = 0; i < minsAgo; i++) {
      var (lowTarget, highTarget, tempTarget) =
          summary.targetAtTime(DateTime.now().subtract(Duration(minutes: i)));
      if (tempTarget != null) {
        lowTargets
            .add(FlSpot(-i.toDouble(), tempTarget.targetBottom.toDouble()));
        highTargets.add(FlSpot(-i.toDouble(), tempTarget.targetTop.toDouble()));
      } else if (lowTarget != null && highTarget != null) {
        lowTargets.add(FlSpot(-i.toDouble(), lowTarget.value));
        highTargets.add(FlSpot(-i.toDouble(), highTarget.value));
      }
    }
    return (lowTargets, highTargets);
  }

  LineTouchData lineTouchData(Settings settings) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.transparent,
        tooltipRoundedRadius: 10.0,
        fitInsideHorizontally: true,
        tooltipMargin: 10,
        tooltipPadding: const EdgeInsets.all(0),
        showOnTopOfTheChartBoxArea: false,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map(
            (LineBarSpot touchedSpot) {
              if (touchedSpot.barIndex != 0) {
                return null;
              }

              //OriginalSpot touchedSpot.bar.spots[touchedSpot.spotIndex];
              return LineTooltipItem(
                settings.unit.str(touchedSpot.y),
                touchedTextStyle,
                textAlign: TextAlign.center,
              );
            },
          ).toList();
        },
      ),
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> indicators) {
        return indicators.map(
          (int index) {
            var line = FlLine(
                color: mainColor.withAlpha(150),
                strokeWidth: 1,
                dashArray: [2, 4]);
            return TouchedSpotIndicatorData(
              line,
              const FlDotData(show: false),
            );
          },
        ).toList();
      },
    );
  }

  FlBorderData borderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: mainColor.withAlpha(50), width: 1),
    );
  }

  FlTitlesData titleData(Settings settings, double maxBasal) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: rightTitleWidgets(maxBasal)),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: bottomTitleWidgets(),
      ),
      leftTitles: AxisTitles(sideTitles: leftTitleWidgets(settings)),
    );
  }

  FlGridData gridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 36,
      verticalInterval: 10,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: mainColor.withAlpha(90),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: mainColor.withAlpha(90),
          strokeWidth: 1,
        );
      },
    );
  }

  RangeAnnotations rangeAnnotations(Settings settings) {
    return RangeAnnotations(
      horizontalRangeAnnotations: [
        HorizontalRangeAnnotation(
          y1: settings.urgentHigh.toDouble(),
          y2: settings.urgentLow.toDouble(),
          color: mainColor.withAlpha(35),
        ),
        HorizontalRangeAnnotation(
          y1: settings.targetHigh.toDouble(),
          y2: settings.targetLow.toDouble(),
          color: mainColor.withAlpha(35),
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
          const style = TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 7,
              color: mainColor,
              height: 0.5);

          //return Spacer if value is not mod 30
          if (value.toInt() % 30 != 0) {
            return const SizedBox();
          }

          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(
                Dates.dateAgoShort(Duration(minutes: value.toInt().abs())),
                style: style),
          );
        });
  }

  SideTitles rightTitleWidgets(double maxBasal) {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 19,
      getTitlesWidget: (double value, TitleMeta meta) {
        const style = TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 6,
            color: mainColor,
            height: 0.5);

        bool drawTitle = (value == basalMultiplier.toDouble() ||
            value == basalMultiplier.toDouble() / 2);

        if (maxBasal == 0) {
          drawTitle = value == 0;
        }

        if (drawTitle) {
          return Text("${value / basalMultiplier * maxBasal}u",
              style: style, textAlign: TextAlign.right);
        }

        return const SizedBox();
      },
    );
  }

  SideTitles leftTitleWidgets(Settings settings) {
    return SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 18,
      getTitlesWidget: (double value, TitleMeta meta) {
        const style = TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 6,
            color: mainColor,
            height: 0.5);

        if (value.toInt() == settings.urgentHigh ||
            value.toInt() == settings.urgentLow ||
            value.toInt() == settings.targetHigh ||
            value.toInt() == settings.targetLow) {
          return Text(settings.unit.str(value),
              style: style, textAlign: TextAlign.right);
        }
        return const SizedBox();
      },
    );
  }

  FlDotPainter bglDotPainter(
    FlSpot spot,
    double xPercentage,
    LineChartBarData bar,
    int index, {
    double? size,
  }) {
    return FlDotCirclePainter(
      radius: 2,
      color: mainColor,
      strokeColor: mainColor,
    );
  }

  FlDotPainter treatmentsDotPainter(
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
          strokeColor: Colors.black,
          size: 8,
          color: mainColor,
        );
      } else if (spot.treatment.insulin != 0) {
        return FlTextPainterPainter(
          spot.treatment.insulinStr,
          strokeColor: Colors.black,
          size: 8,
          color: mainColor,
        );
      } else if (spot.treatment.carbs != 0) {
        return FlTextPainterPainter(
          spot.treatment.carbStr,
          strokeColor: Colors.black,
          size: 8,
          color: mainColor,
        );
      }
    }
    return FlDotCirclePainter(
      radius: 0,
      color: mainColor,
      strokeColor: mainColor,
    );
  }
}

/// This class is an implementation of a [FlDotPainter] that draws Text on a canvas
class FlTextPainterPainter extends FlDotPainter {
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
  }) {
    circle = FlDotCirclePainter(
      radius: 2,
      color: color,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }

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
        shadows: [
          Shadow(
              // bottomLeft
              offset: Offset(-strokeWidth, -strokeWidth),
              color: strokeColor),
          Shadow(
              // bottomRight
              offset: Offset(strokeWidth, -strokeWidth),
              color: strokeColor),
          Shadow(
              // topRight
              offset: Offset(strokeWidth, strokeWidth),
              color: strokeColor),
          Shadow(
              // topLeft
              offset: Offset(-strokeWidth, strokeWidth),
              color: strokeColor),
        ]);
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

    final centeredOffset = offsetInCanvas.translate(
      -painter.width / 2,
      -painter.height / 2 + painter.height + 3,
    );

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
