class Errors {
  static captureException(
    dynamic throwable, {
    dynamic stackTrace,
  }) async {
    // TODO actuall handle error here, or reraise
    print("THROWING $throwable");
    print(stackTrace);
  }
}
