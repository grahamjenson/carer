import "dart:developer" as developer;

import "package:carer/services/settings/secure_settings.dart";
import "package:carer/utils/env.dart";
import "package:clock/clock.dart";
import "package:sentry_flutter/sentry_flutter.dart";
import "package:signals/signals_flutter.dart";

enum LogLevel {
  info(1),
  debug(2),
  warning(3),
  error(4);

  final int level;
  const LogLevel(this.level);
}

class ALogger {
  final signal = Signal(0, debugLabel: "ALoggerSignal");

  ALogger._internal();
  static final ALogger _instance = ALogger._internal();
  factory ALogger() => _instance;

  List<(DateTime, LogLevel, String)> logLines = [];

  void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    LogLevel level = LogLevel.debug,
    String name = '',
  }) {
    message = censorLogs(message);

    var now = clock.now();
    signal.value = now.millisecondsSinceEpoch;
    logLines.insert(0, (now, level, message));

    if (logLines.length > 10000) {
      logLines = logLines.sublist(0, 10000);
    }

    developer.log(
      message,
      level: level.level,
      time: now,
    );
  }

  String censorLogs(String msg) {
    var (nsurl, token) = SecureSettings().nightscoutURLAndToken;
    if (nsurl.isNotEmpty) {
      msg = msg.replaceAll(nsurl, "NS_URL").replaceAll(token, "NS_TOKEN");
    }
    return msg;
  }

  getPrettyLogs() {
    return logLines.map((e) => "${e.$1}\t  ${e.$2.name}  \t${e.$3}").join("\n");
  }
}

alog(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  LogLevel level = LogLevel.debug,
  String name = '',
  Object? error,
  StackTrace? stackTrace,
}) {
  ALogger().log(message, time: time, sequenceNumber: sequenceNumber, level: level, name: name);
}

////
// ERRORS
////

class Errors {
  static captureError(Object e, StackTrace stacktrace, {String? name}) {
    var internalLines = stacktrace.toString().split("\n").where((element) => element.contains(RegExp("package:carer|file://"))).toList();
    if (internalLines.isNotEmpty) {
      alog("ERROR $name\n$e\n${internalLines.join("\n")}", level: LogLevel.error);
    } else {
      alog("ERROR $name\n$e\n$stacktrace", level: LogLevel.error);
    }

    if (Env.isTest) {
      throw e;
    }
    if (Env.isProd) {
      Sentry.captureException(
        e,
        stackTrace: stacktrace,
        hint: Hint.withMap(
          {
            'name': name,
          },
        ),
      );
    }
  }
}
