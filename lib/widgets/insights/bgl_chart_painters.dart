import 'package:carer/models/sql/sgv.dart';
import 'package:carer/models/treatment_group.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/math.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TreatmentSpot extends FlSpot {
  final Treatment treatment;
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

class PainterFunctions with ThemeMixin {
  // singleton
  static final PainterFunctions _instance = PainterFunctions._internal();
  factory PainterFunctions() => _instance;
  PainterFunctions._internal();

  // Painter used when spots on a veritcal line is slected
  GetDotPainterCallback highlightPainer(BuildContext context) {
    var color = primaryColor(context);
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      if (spot is BGLSpot) {
        var circle = FlDotCirclePainter(
          radius: 4,
          color: Colors.black,
          strokeColor: color,
          strokeWidth: 2,
        );

        if (!spot.sgv.isNormal) {
          circle = FlDotCirclePainter(
            radius: 3,
            color: badColor(context),
            strokeColor: color,
            strokeWidth: 2,
          );
        }
        Color textColor = color;
        if (!spot.sgv.isNormal) {
          textColor = badColor(context);
        }
        return FlTextPainterPainter(
          spot.sgv.sgvStr(),
          strokeColor: Colors.black,
          size: 24,
          color: textColor,
          align: Alignment.topCenter,
          shapePainter: circle,
        );
      }

      if (spot is BasalSpot) {
        return FlTextPainterPainter(
          "${toMax2dp(spot.basal)}",
          strokeColor: Colors.black,
          size: 16,
          color: color,
          align: Alignment.topCenter,
        );
      }

      if (spot is TreatmentSpot) {
        String text = spot.treatment.treatmentStr;
        if (spot.treatment.isSmb) {
          text = "${spot.treatment.treatmentStr}*";
        }
        var pcolor = color;
        var align = Alignment.topCenter;
        if (spot.treatment.isBolus) {
          pcolor = accentColor(context);
          align = Alignment.bottomCenter;
        }

        var painter = _getPainterForTreatmentSpot(spot.treatment, context, size: 1.3);
        return FlTextPainterPainter(
          text,
          align: align,
          strokeColor: Colors.black,
          size: 16,
          strokeWidth: 2,
          color: pcolor,
          shapePainter: painter,
        );
      }
      return FlDotCirclePainter(
        radius: 0,
        color: color,
        strokeColor: color,
      );
    };
  }

  GetDotPainterCallback treatmentsDotPainter(
    BuildContext context, {
    double size = 1,
  }) {
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index,
    ) {
      if (spot is! TreatmentSpot) {
        return FlDotCirclePainter(
          radius: 0,
        );
      }
      return _getPainterForTreatmentSpot(spot.treatment, context);
    };
  }

  ChevronDotPainter _getPainterForTreatmentSpot(Treatment treatment, BuildContext context, {double size = 1}) {
    if (treatment.isSmb) {
      return ChevronDotPainter(
        isUp: false,
        size: 6 * size,
        color: accentColor(context).dim.dim,
        strokeColor: accentColor(context).dim,
      );
    }
    if (treatment.isBolus) {
      return ChevronDotPainter(
        isUp: false,
        size: 6 * size,
        color: accentColor(context),
        strokeColor: accentColor(context),
      );
    }
    // Carbs
    return ChevronDotPainter(
      isUp: true,
      size: 6 * size,
      color: primaryColor(context),
      strokeColor: primaryColor(context),
    );
  }

  GetDotPainterCallback bglDotPainter(BuildContext context) {
    Color color = primaryColor(context);
    Color outOfRangeColor = badColor(context);
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      BGLSpot bglspot = spot as BGLSpot;
      var useColor = Colors.black;
      var useStrokeColor = color;
      double useStokeWidth = .8;
      double useRadius = 3;
      if (!bglspot.sgv.isNormal) {
        useColor = outOfRangeColor;
        useRadius = 1.5;
        useStokeWidth = 1;
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
}

/// This class is an implementation of a [FlDotPainter] that draws Text on a canvas
class FlTextPainterPainter extends FlDotPainter with ThemeMixin {
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
    this.shapePainter,
  });

  final Alignment align;

  final FlDotPainter? shapePainter;

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
    if (shapePainter != null) {
      shapePainter!.draw(canvas, spot, offsetInCanvas);
    }

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
    return b;
  }
}

class ChevronDotPainter extends FlDotPainter {
  final bool isUp;
  final Color color;
  final Color strokeColor;
  final double size;

  ChevronDotPainter({
    required this.isUp,
    required this.color,
    required this.strokeColor,
    this.size = 10.0,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    if (isUp) {
      path.moveTo(offset.dx, offset.dy - size / 2);
      path.lineTo(offset.dx - size / 2, offset.dy + size / 2);
      path.lineTo(offset.dx + size / 2, offset.dy + size / 2);
    } else {
      path.moveTo(offset.dx, offset.dy + size / 2);
      path.lineTo(offset.dx - size / 2, offset.dy - size / 2);
      path.lineTo(offset.dx + size / 2, offset.dy - size / 2);
    }
    path.close();

    canvas.drawPath(path, strokePaint);
    canvas.drawPath(path, paint);
  }

  /// Implementation of the parent class to get the size of the square
  @override
  Size getSize(FlSpot spot) {
    return Size(size, size);
  }

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    return b;
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        color,
        size,
        isUp,
      ];

  @override
  Color get mainColor => color;
}
