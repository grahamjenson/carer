import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class Env {
  static const bool isDev = kDebugMode;
  static bool isTest = Platform.environment.containsKey('FLUTTER_TEST');
  static bool isProd = !isTest && !isDev;

  static bool profileOn = isDev;

  static bool catchErrors = isTest;
}
