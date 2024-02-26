import 'package:carer/models/settings_cn.dart';
import 'package:carer/models/summary_cn.dart';
import 'package:carer/nsclient/summary.dart';
import 'package:carer/utils/dates.dart';
import 'package:carer/widgets/colours.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BGLChart extends StatelessWidget {
  const BGLChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Settings, SummaryCN>(
        builder: (context, settings, summaryCn, child) {
      int minsAgo = 125;
      // Breaking down the objects
      Summary summary = summaryCn.summary;
      List<SGV> sgvs = summary.sgvs.lastMins(minsAgo);

      double maxY = settings.urgentHigh + 36;
      double minY = 0;
      double minX = -1 * minsAgo.toDouble(); // mins ago
      double maxX = 0; // now

      // convert the last hours of summary sgvs into flspots
      List<FlSpot> spots = [];
      for (var i = 0; i < sgvs.length; i++) {
        var sgv = sgvs[i];
        spots.add(FlSpot(-sgv.age.inMinutes.toDouble(), sgv.sgv.toDouble()));
      }

      return Container(
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(color: mainColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: mainColor,
              ),
              child: const Text("Chart",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 10,
                  )),
            ),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                      top: 5,
                    ),
                    child: LineChart(
                      LineChartData(
                        rangeAnnotations: RangeAnnotations(
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
                        ),
                        gridData: FlGridData(
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
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: bottomTitleWidgets(),
                          ),
                          leftTitles: AxisTitles(
                              sideTitles: leftTitleWidgets(settings)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: mainColor.withAlpha(50), width: 1),
                        ),
                        maxX: maxX,
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            color: mainColor,
                            spots: spots,
                            barWidth: 2,
                            dotData: FlDotData(
                                show: true, getDotPainter: bglDotPainter),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.transparent,
                              tooltipRoundedRadius: 10.0,
                              showOnTopOfTheChartBoxArea: true,
                              fitInsideHorizontally: true,
                              tooltipMargin: -20,
                              tooltipPadding: const EdgeInsets.all(0),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map(
                                  (LineBarSpot touchedSpot) {
                                    const textStyle = TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    );
                                    return LineTooltipItem(
                                      settings.unit
                                          .str(spots[touchedSpot.spotIndex].y),
                                      textStyle,
                                    );
                                  },
                                ).toList();
                              },
                            ),
                            getTouchedSpotIndicator: (LineChartBarData barData,
                                List<int> indicators) {
                              return indicators.map(
                                (int index) {
                                  const line = FlLine(
                                      color: Colors.grey,
                                      strokeWidth: 1,
                                      dashArray: [2, 4]);
                                  return const TouchedSpotIndicatorData(
                                    line,
                                    FlDotData(show: false),
                                  );
                                },
                              ).toList();
                            },
                            getTouchLineEnd: (_, __) => double.infinity),
                      ),
                    ))),
          ],
        ),
      );
    });
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
}
