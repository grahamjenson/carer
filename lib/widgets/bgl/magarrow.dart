import 'dart:async';
import 'dart:math';

import 'package:carer/models/sgv.dart';
import 'package:carer/services/settings/target_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/utils/math.dart';
import 'package:flutter/material.dart';

class MagArrow extends StatefulWidget {
  const MagArrow({super.key});

  @override
  State<MagArrow> createState() => _MagArrowState();
}

class _MagArrowState extends State<MagArrow> with ThemeMixin {
  int diff = 0;
  int limit = 3;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Using a timer here instead of animation, because 60fps for this is overkill;
    // I think using an animatino for this is bad because it used lots of power for nothing much
    _timer = Timer.periodic(const Duration(milliseconds: 250), (Timer t) {
      var previousDiff = diff;
      diff = (diff + 1) % limit;
      if (diff != previousDiff) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AWatch((context) {
      var mag = findMagnitude();
      int? value = mag;
      if (mag == null) {
        value = mag;
      } else if (mag == 0) {
        value = 0;
        diff = 0;
        limit = 1;
      } else if (mag > 0) {
        value = diff;
        limit = mag.abs() + 1;
      } else if (mag < 0) {
        value = -diff;
        limit = mag.abs() + 1;
      }

      return AspectRatio(
        aspectRatio: 0.3,
        child: CustomPaint(
          painter: MyPainter(value, primaryColor(context)),
        ),
      );
    });
  }
}

int? findMagnitude() {
  var mag = 0;
  switch (diffRange7()) {
    case Range7.veryVeryLow:
      mag = -3;
      break;
    case Range7.veryLow:
      mag = -2;
      break;
    case Range7.low:
      mag = -1;
      break;
    case Range7.mid:
      mag = 0;
      break;
    case Range7.high:
      mag = 1;
      break;
    case Range7.veryHigh:
      mag = 2;
      break;
    case Range7.veryVeryHigh:
      mag = 3;
      break;
  }
  return mag;
}

Range7 diffRange7() {
  var lastSGV = CleanSGV.lastSGV.value;
  if (lastSGV == null) {
    return Range7.mid;
  }
  var (dr, _) = diffRange(TargetSettings().fastDropDelta, TargetSettings().fastRiseDelta, lastSGV.rate5m ?? 0);

  return dr;
}

class MyPainter extends CustomPainter {
  int? magnitutude;
  Color primaryColor;
  MyPainter(this.magnitutude, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    Color main = primaryColor;
    Color dim = primaryColor.withAlpha(75);

    Paint paint = Paint();
    double minV = min(size.height, size.width);
    paint.color = main;

    paint.strokeWidth = minV * 0.2;
    paint.style = PaintingStyle.stroke;
    // Path number 1

    size = size;

    // center
    // We always draw center
    if (magnitutude == null) {
      drawCenter(size, paint, dim, canvas);
    } else {
      drawCenter(size, paint, main, canvas);
    }

    // up
    switch (magnitutude) {
      case 3:
        drawUp3(size, paint, main, canvas);
        drawUp2(size, paint, main, canvas);
        drawUp1(size, paint, main, canvas);

        drawDown1(size, paint, dim, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);

        break;
      case 2:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, main, canvas);
        drawUp1(size, paint, main, canvas);
        drawDown1(size, paint, dim, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);

        break;
      case 1:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, main, canvas);

        drawDown1(size, paint, dim, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);
        break;
      case 0:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, dim, canvas);

        drawDown1(size, paint, dim, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);
      case -1:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, dim, canvas);

        drawDown1(size, paint, main, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);
        break;
      case -2:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, dim, canvas);

        drawDown1(size, paint, main, canvas);
        drawDown2(size, paint, main, canvas);
        drawDown3(size, paint, dim, canvas);
        break;
      case -3:
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, dim, canvas);

        drawDown1(size, paint, main, canvas);
        drawDown2(size, paint, main, canvas);
        drawDown3(size, paint, main, canvas);
        break;
      default: // 0
        drawUp3(size, paint, dim, canvas);
        drawUp2(size, paint, dim, canvas);
        drawUp1(size, paint, dim, canvas);

        drawDown1(size, paint, dim, canvas);
        drawDown2(size, paint, dim, canvas);
        drawDown3(size, paint, dim, canvas);
    }
  }

  void drawCenter(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0.22, 0.50], [0.5, 0.46]);
    drawMultiPointLine(size, canvas, paint, color, [0.26, 0.50], [0.5, 0.54]);
  }

  void drawUp1(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.45, 0.35]);
  }

  void drawUp2(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.34, 0.24]);
  }

  void drawUp3(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.23, 0.13]);
  }

  void drawDown1(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.55, 0.65]);
  }

  void drawDown2(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.66, 0.76]);
  }

  void drawDown3(size, paint, color, canvas) {
    drawMultiPointLine(size, canvas, paint, color, [0, 0.50], [0.77, 0.87]);
  }

  void drawMultiPointLine(
    Size size,
    Canvas canvas,
    Paint paint,
    Color color,
    List<double> xs,
    List<double> ys,
  ) {
    paint.color = color;
    xs.add(1 - xs[0]); // mirror x
    ys.add(ys[0]); // mirror y
    Path path = Path();
    path.moveTo(size.width * xs[0], size.height * ys[0]);

    for (int i = 1; i < xs.length; i++) {
      path.lineTo(size.width * xs[i], size.height * ys[i]);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
