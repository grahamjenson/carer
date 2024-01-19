import 'package:sentry_flutter/sentry_flutter.dart';

class Errors {
  static captureException(
    dynamic throwable, {
    dynamic stackTrace,
    Hint? hint,
    ScopeCallback? withScope,
  }) async {
    // TODO actuall handle error here, or reraise
    print("THROWING ${throwable}");
    print(stackTrace);
  }
}
