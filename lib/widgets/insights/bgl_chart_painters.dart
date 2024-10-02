import 'package:carer/models/sql/bolus.dart';
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
    var color = accentColor(context);
    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index, {
      double? size,
    }) {
      if (spot is BGLSpot) {
        return FlTextPainterPainter(
          spot.sgv.sgvStr(),
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
        return treatmentsDotPainter(context, size: 2)(
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

  GetDotPainterCallback treatmentsDotPainter(
    BuildContext context, {
    double size = 1,
    bool justShape = false,
  }) {
    var color = primaryColor(context);

    return (
      FlSpot spot,
      double xPercentage,
      LineChartBarData bar,
      int index,
    ) {
      if (spot is! TreatmentSpot) {
        return FlDotCirclePainter(
          radius: 2,
          color: color,
          strokeColor: color,
        );
      }

      var pcolor = color;
      String text = spot.treatment.treatmentStr;
      bool isSMB = false;
      if (spot.treatment.bolus != null) {
        pcolor = Colors.blue;
        if (spot.treatment.bolus!.type == BolusType.smb) {
          text = "${spot.treatment.treatmentStr}*";
          isSMB = true;
        }
      }

      if (justShape) {
        if (isSMB) {
          return FlDotCrossPainter(
            size: 5,
            color: pcolor,
          );
        }
        if (spot.treatment.bolus != null) {
          return FlDotSquarePainter(
            size: 5,
            color: pcolor,
            strokeColor: Colors.black,
          );
        }
        return FlDotCirclePainter(
          radius: 2,
          color: pcolor,
          strokeColor: Colors.black,
        );
      }

      return FlTextPainterPainter(
        text,
        align: Alignment.topCenter,
        strokeColor: Colors.black,
        size: 8 * size,
        strokeWidth: size,
        color: pcolor,
      );
    };
  }

  GetDotPainterCallback bglDotPainter(BuildContext context) {
    var color = primaryColor(context);
    var outOfRangeColor = Colors.red;
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
  });
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
    var circle = FlDotCirclePainter(
      radius: 3,
      color: color,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
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
    return b;
  }
}

class ChevronDotPainter extends FlDotPainter {
  final bool isUp;
  final Color color;
  final double size;

  ChevronDotPainter({
    required this.isUp,
    required this.color,
    this.size = 10.0,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

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
