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
  } catch (e) {
    // TODO log the error somewhere with good trace to debug
    return (null, e);
  }
}

// FutureSignal<T> gos<T>(FutureSignal<T> ft) {
//   return computedAsync(callback: () => go(ft.value), dependencies: [ft]);
// }

class WatchWE<T extends Widget> extends StatelessWidget {
  const WatchWE(this.builder, {super.key});

  /// The widget to rebuild when any signals change
  final T Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      try {
        return builder(context);
      } catch (e, stackTrace) {
        // Only report stack for internal lines
        var internalLines = stackTrace.toString().split("\n").where((element) => element.contains("package:carer")).toList();
        if (internalLines.isNotEmpty) {
          print("ERROR\n$e\n${internalLines.join("\n")}");
        } else {
          print("ERROR\n$e\n$stackTrace");
        }

        if (kDebugMode) {
          return ErrorWidget(e);
        }

        // If not debug

        // Report to Sentry
        Sentry.captureException(
          e,
          stackTrace: stackTrace,
        );
        // Return instructinos on reporting
        return const Text("Error. Please restart the app. If continues, please contact support.");
      }
    });
  }
}
