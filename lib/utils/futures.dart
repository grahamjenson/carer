import 'dart:async';

import 'package:carer/utils/env.dart';
import 'package:carer/utils/logs.dart';
import 'package:carer/utils/strings.dart';
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

Future<T> executeWithRetry<T>(
  Future<T> Function() task, {
  int maxRetries = 3,
  Duration retryDelay = const Duration(milliseconds: 100),
}) async {
  int retries = 0;
  while (true) {
    try {
      // Attempt to execute the task
      return await task();
    } catch (error) {
      // If an error occurs, check if the retry limit is reached
      if (retries >= maxRetries) {
        // If the retry limit is exceeded, rethrow the error
        rethrow;
      }
      // Log the error and retry after a delay
      print('Attempt $retries failed: $error');
      await Future.delayed(retryDelay);
      retries++;
    }
  }
}

////
// Signals Wrappers
////

class ASignal<T> extends Signal<T> {
  DateTime lastSet = DateTime.now();
  T defaultVal;

  ASignal(
    this.defaultVal, {
    required super.debugLabel,
    super.autoDispose,
  }) : super(defaultVal) {
    registerSignal(super.debugLabel!, signal: this);
  }

  @override
  bool set(T val, {bool force = false}) {
    bool ret = super.set(val, force: force);
    if (ret) {
      lastSet = DateTime.now(); // Needs to be DateTime.now not Clock.now to stop the tests from stubbing the date
      alog(truncateString("ASignal: $debugLabel set to $val", 100));
    }
    return ret;
  }

  Duration get lastSetAgo => DateTime.now().difference(lastSet);

  // For Test Purposes Mostly
  void reset() {
    set(defaultVal);
  }
}

class ATimerSignal extends TimerSignal {
  ATimerSignal({
    required super.every,
    required super.debugLabel,
    super.autoDispose,
  });
}

class AWatch<T extends Widget> extends StatelessWidget {
  final List<Signal> dependencies;
  final String debugLabel;
  final bool doLog;

  const AWatch(this.builder, {super.key, this.dependencies = const [], required this.debugLabel, this.doLog = false});

  /// The widget to rebuild when any signals change
  final T Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) {
        try {
          for (var dep in dependencies) {
            dep.value;
          }
          if (doLog) {
            alog("AWatch: $debugLabel rebuild");
          }
          return builder(context);
        } catch (e, stackTrace) {
          // Only report stack for internal lines
          Errors.captureError(e, stackTrace);

          if (!Env.isProd) {
            return ErrorWidget(e);
          }
          // Return instructinos on reporting
          return const Text("Error. Please restart the app. If continues, please contact support.");
        }
      },
      debugLabel: this.debugLabel,
    );
  }
}

Future<EffectCleanup> signalAssign<T>(
  ASignal<T> signal,
  FutureOr<T> Function() fn, {
  required String debugLabel,
  List<ReadonlySignal<dynamic>> dependencies = const [],
  lazy = false,
}) async {
  if (!lazy) {
    signal.value = await fn();
  }
  return aeffect(
    () {
      final result = fn();
      if (result is Future) {
        untracked(() async {
          signal.value = await result;
        });
      } else {
        untracked(() {
          signal.value = result;
        });
      }
    },
    debugLabel: debugLabel,
    dependencies: dependencies,
    doLog: false, // Dont log because signal should log
  );
}

EffectCleanup aeffect(
  EffectCallback compute, {
  required String debugLabel,
  EffectCallback? onDispose,
  List<ReadonlySignal<dynamic>> dependencies = const [],
  doLog = false,
}) {
  registerSignal(debugLabel);
  return effect(() {
    try {
      for (var dep in dependencies) {
        dep.value;
      }
      var val = compute();
      if (doLog) {
        alog(truncateString("AEffect: $debugLabel returned $val", 100));
      }
      return val;
    } catch (e, stackTrace) {
      Errors.captureError(e, stackTrace);
    }
  }, debugLabel: debugLabel, onDispose: onDispose);
}

class SignalsDevObserverWrapper extends DevToolsSignalsObserver {
  @override
  void log(String message) {
    // Don't log here, because this will never work in prod because Signals use `assert` block to notify observer
  }
}

void setupSignalsLogging() {
  // if kdebug is true, then it will be a DevToolsSignalsObserver
  SignalsObserver? oldinstance = SignalsObserver.instance;
  if (oldinstance != null && oldinstance is DevToolsSignalsObserver) {
    oldinstance.enabled = false;
    var newinstance = SignalsDevObserverWrapper();
    SignalsObserver.instance = newinstance;
  }
}

// To make sure initialization is good and DebugLabels are unique we keep track of all registered signals and force unique debugLabels
Set<String> _registeredSignals = {};
Set<ASignal> _allSignals = {};

bool registerSignal(String debugLabel, {ASignal? signal}) {
  if (_registeredSignals.contains(debugLabel)) {
    var message = "VERY BAD: Signal with debugLabel $debugLabel already registered";
    if (Env.isProd) {
      // In prod dont be so mean
      alog(message);
      print(message);
      return false;
    } else {
      throw message;
    }
  }
  _registeredSignals.add(debugLabel);
  if (signal != null) {
    _allSignals.add(signal);
  }
  return true;
}

void resetAllSignals() {
  for (var signal in _allSignals) {
    signal.reset();
  }
}
