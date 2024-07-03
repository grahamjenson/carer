import 'package:carer/utils/env.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Errors {
  static captureError(Object e, StackTrace stacktrace, {String? name}) {
    var internalLines = stacktrace.toString().split("\n").where((element) => element.contains(RegExp("package:carer|file://"))).toList();
    if (internalLines.isNotEmpty) {
      print("ERROR $name\n$e\n${internalLines.join("\n")}");
    } else {
      print("ERROR $name\n$e\n$stacktrace");
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
