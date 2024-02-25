import 'dart:math';

import 'package:carer/widgets/colours.dart';
import 'package:flutter/material.dart';

class MagArrow extends StatefulWidget {
  int magnitute;

  // -3 -2 -1 0 1 2 3 repre
  MagArrow({super.key, required this.magnitute});

  @override
  State<MagArrow> createState() => _MagArrowState();
}

class _MagArrowState extends State<MagArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          const Duration(seconds: 1), // Change this to your desired duration
      vsync: this,
    )..repeat();
    _animation = IntTween(begin: 0, end: widget.magnitute).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _animation = IntTween(begin: 0, end: widget.magnitute).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    return AspectRatio(
      aspectRatio: 0.3,
      child: CustomPaint(
        painter: MyPainter(_animation.value),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  int magnitutude;
  MyPainter(this.magnitutude);

  @override
  void paint(Canvas canvas, Size size) {
    Color main = mainColor;
    Color dim = mainColor.withAlpha(75);

    Paint paint = Paint();
    double minV = min(size.height, size.width);
    paint.color = main;

    paint.strokeWidth = minV * 0.2;
    paint.style = PaintingStyle.stroke;
    // Path number 1

    size = size;

    // center
    // We always draw center
    drawCenter(size, paint, main, canvas);

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
