import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:signals/signals_flutter.dart';

Future<T> futureProfile<T>(String name, Future<T> toMeasure) {
  // Dont profile on tests
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return toMeasure;
  }
  Future<T> x = Future(() {
    var stopwatch = Stopwatch()..start();
    return stopwatch;
  }).then((sw) async => (sw, await toMeasure)).then((d) {
    var (sw, r) = d;
    print('$name executed in ${sw.elapsed.inMilliseconds}ms');
    //
    return r;
    //
  });

  return x;
}

Future<(T?, Object?)> go<T>(Future<T> ft) async {
  try {
    var x = await ft;
    return (x, null);
  } catch (e, stackTrace) {
    logError(e, stackTrace);
    return (null, e);
  }
}

class AWatch<T extends Widget> extends StatelessWidget {
  const AWatch(this.builder, {super.key});

  /// The widget to rebuild when any signals change
  final T Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      try {
        return builder(context);
      } catch (e, stackTrace) {
        // Only report stack for internal lines
        logError(e, stackTrace);

        if (kDebugMode) {
          return ErrorWidget(e);
        }
        // Return instructinos on reporting
        return const Text("Error. Please restart the app. If continues, please contact support.");
      }
    });
  }
}

EffectCleanup aeffect(
  EffectCallback compute, {
  String? debugLabel,
  EffectCallback? onDispose,
}) {
  return effect(() {
    try {
      return compute();
    } catch (e, stackTrace) {
      logError(e, stackTrace);
    }
  }, debugLabel: debugLabel, onDispose: onDispose);
}

Computed<T> acomputed<T>(
  ComputedCallback<T> compute,
  T onError, {
  String? debugLabel,
  bool autoDispose = false,
}) {
  return computed(() {
    try {
      return compute();
    } catch (e, stackTrace) {
      logError(e, stackTrace);
      return onError;
    }
  }, debugLabel: debugLabel, autoDispose: autoDispose);
}

FutureSignal<T> acomputedAsync<T>(
  Future<T> Function() callback,
  T initialValue, {
  String? debugLabel,
  bool autoDispose = false,
  List<ReadonlySignal<dynamic>> dependencies = const [],
  bool lazy = true,
}) {
  return computedAsync(() async {
    try {
      return await callback();
    } catch (e, stackTrace) {
      logError(e, stackTrace);
      return initialValue;
    }
  }, initialValue: initialValue, debugLabel: debugLabel, autoDispose: autoDispose, dependencies: dependencies, lazy: lazy);
}

logError(e, stacktrace) {
  var internalLines = stacktrace.toString().split("\n").where((element) => element.contains("package:carer")).toList();
  if (internalLines.isNotEmpty) {
    print("ERROR\n$e\n${internalLines.join("\n")}");
  } else {
    print("ERROR\n$e\n$stacktrace");
  }

  if (!kDebugMode) {
    Sentry.captureException(
      e,
      stackTrace: stacktrace,
    );
  }
}
