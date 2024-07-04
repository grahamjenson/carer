import 'package:carer/utils/env.dart';
import 'package:carer/utils/errors.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

////
// ASYNC wrapper
////

Future<(T?, Object?)> go<T>(Future<T> ft, {String? name, bool? profile}) async {
  Stopwatch? stopwatch;

  if (profile == true && Env.profileOn) {
    stopwatch = Stopwatch()..start();
  }

  return ft.then((value) {
    _closeOutProfile(stopwatch, name, "success");
    return (value as T?, null as Object?);
  }).catchError((e, StackTrace stackTrace) {
    Errors.captureError(e, stackTrace, name: name);
    _closeOutProfile(stopwatch, name, "error");
    return (null, e);
  });
}

_closeOutProfile(Stopwatch? stopwatch, String? name, String msg) {
  if (stopwatch != null) {
    stopwatch.stop();
    alog('$name($msg) executed in ${stopwatch.elapsed.inMilliseconds}ms');
  }
}

////
// Signals Wrappers
////

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
        Errors.captureError(e, stackTrace);

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
      Errors.captureError(e, stackTrace);
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
      Errors.captureError(e, stackTrace);
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
      Errors.captureError(e, stackTrace);
      return initialValue;
    }
  }, initialValue: initialValue, debugLabel: debugLabel, autoDispose: autoDispose, dependencies: dependencies, lazy: lazy);
}
