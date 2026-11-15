import "dart:developer" as developer;

import "package:carer/sql/log_db.dart";
import "package:carer/utils/env.dart";
import "package:clock/clock.dart";
import "package:sentry_flutter/sentry_flutter.dart";

enum LogLevel {
  info(1),
  debug(2),
  warning(3),
  error(4);

  final int level;
  const LogLevel(this.level);
}

class ALogger {
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
    time ??= clock.now();

    message = censorLogs(message);

    logLines.insert(0, (time, level, message));

    if (logLines.length > 10000) {
      logLines = logLines.sublist(0, 10000);
    }

    // Wrap in golang to avoid errors
    try {
      LogDB.writeLog(time, message, level.level);
    } catch (e, stacktrace) {
      // Dont handle the error since that is a BAD loop
      print("Error $e\n$stacktrace");
    }

    developer.log(
      "$time $message",
      level: level.level,
      time: time,
    );
  }

  final Map<String, String> _censoredString = {};
  void addCensoredString(String replacement, String string) {
    _censoredString[replacement] = string;
  }

  String censorLogs(String msg) {
    for (var entry in _censoredString.entries) {
      msg = msg.replaceAll(entry.value, entry.key);
    }
    return msg;
  }

  String getPrettyLogs() {
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

    if (Env.isTest && Env.catchErrors) {
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
