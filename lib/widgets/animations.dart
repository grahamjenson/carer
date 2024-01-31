import 'package:flutter/material.dart';

const List<(double, double, double)> scaleWeights = [
  (1.2, 0.8, 1),
  (0.8, 1.5, 1),
  (1.5, 0.5, 1),
  (0.5, 1.3, 1),
  (1.3, 1, 1),
  (1, 1, 4)
];

TweenSequence<double> heartBeatTS() {
  return TweenSequence([
    for (var (s1, s2, w) in scaleWeights)
      TweenSequenceItem(tween: Tween<double>(begin: s1, end: s2), weight: w)
  ]);
}
