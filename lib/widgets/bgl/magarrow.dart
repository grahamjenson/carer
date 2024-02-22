import 'dart:math';

import 'package:flutter/material.dart';

enum Direction {
  up,
  down,
  left,
  right,
}

enum Magnitute {
  small,
  medium,
  large,
}

class MagArrow extends StatelessWidget {
  final Direction direction;
  final Magnitute magnitute;

  const MagArrow({super.key, required this.direction, required this.magnitute});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7,
      child: CustomPaint(
        painter: MyPainter(direction, magnitute),
      ),
    );
  }
}

// 1.7 34.2
// 19.8 50
// 1.7 65.8

// 22.8 20.7
// 56.4 50
// 22.8 79.2

// 49.4 9.3
// 96 50
// 49.4 90.7

class MyPainter extends CustomPainter {
  Magnitute magnitutude;
  Direction direction;
  MyPainter(this.direction, this.magnitutude);

  @override
  void paint(Canvas canvas, Size size) {
    Color main = const Color.fromARGB(255, 199, 210, 172);
    Color dim = const Color.fromARGB(75, 199, 210, 172);

    Paint paint = Paint();
    double minV = min(size.height, size.width);
    paint.color = main;

    paint.strokeWidth = minV * 0.1;
    paint.style = PaintingStyle.stroke;
    // Path number 1

    size = size;

    // center
    drawMultiPointLine(size, canvas, paint, [0.43, 0.50], [0.5, 0.46]);
    drawMultiPointLine(size, canvas, paint, [0.57, 0.50], [0.5, 0.54]);

    // up
    if (direction == Direction.up) {
      paint.color = main;
    } else {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.32, 0.50], [0.45, 0.35]);

    if (magnitutude == Magnitute.small) {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.21, 0.50], [0.4, 0.24]);
    if (magnitutude == Magnitute.medium) {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.1, 0.50], [0.35, 0.13]);

    // down
    if (direction == Direction.down) {
      paint.color = main;
    } else {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.32, 0.50], [0.55, 0.65]);

    if (magnitutude == Magnitute.small) {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.21, 0.50], [0.6, 0.76]);

    if (magnitutude == Magnitute.medium) {
      paint.color = dim;
    }

    drawMultiPointLine(size, canvas, paint, [0.1, 0.50], [0.65, 0.87]);
  }

  void drawMultiPointLine(
      Size size, Canvas canvas, Paint paint, List<double> xs, List<double> ys) {
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
