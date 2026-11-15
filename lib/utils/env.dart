import 'dart:io';

import 'package:flutter/foundation.dart';

// flutter run --release --dart-define=BUILD_TYPE=local
const String buildType = String.fromEnvironment('BUILD_TYPE', defaultValue: 'unknown');

abstract class Env {
  static const bool isDev = kDebugMode;
  static bool isTest = Platform.environment.containsKey('FLUTTER_TEST');
  static bool isProd = !isTest && !isDev;

  static bool profileOn = isDev;

  static bool catchErrors = isTest;

  static String version = '0.0.1';

  static bool isLocalBuild = buildType == "local";
}
