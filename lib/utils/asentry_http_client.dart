import 'package:carer/utils/logs.dart';
import 'package:http/http.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

//
const String replacementHost = "nsurl.com";
final Uri replacementUri = Uri.parse("https://$replacementHost");

Uri replacementUriWithPath(String path) => Uri.parse("https://$replacementHost$path");

const List<String> ignoredExceptions = [
  'The request timed out',
  'The Internet connection appears to be offline',
  'Bad file descriptor', // ref https://github.com/dart-lang/http/issues/197
  'Software caused connection abort',
  'Failed host lookup',
  'No route to host',
  'Could not connect to the server.',
  'Connection closed before full header was received',
  'The network connection was lost',
  'Connection reset by peer',
  'Connection terminated during handshake',
  'An SSL error has occurred and a secure connection to the server cannot be made',
];

/// This is mostly copy pasted from the Sentry package because I dont want to write BaseURLs to Sentry
/// NSURLS are private and there is no easy way to sanitize them out
class ASentryHttpClient extends BaseClient {
  ASentryHttpClient({
    required Client client,
  }) {
    _hub = HubAdapter();

    var innerClient = client;

    innerClient = AFailedRequestClient(innerClient, _hub);

    innerClient = ATracingClient(innerClient, _hub);

    // The ordering here matters.
    // We don't want to include the breadcrumbs for the current request
    // when capturing it as a failed request.
    // However it still should be added for following events.
    innerClient = ABreadcrumbClient(innerClient, _hub);

    _client = innerClient;
  }

  late Client _client;
  late Hub _hub;

  @override
  Future<StreamedResponse> send(BaseRequest request) => _client.send(request);

  // See https://github.com/getsentry/sentry-dart/pull/226#discussion_r536984785
  @override
  void close() => _client.close();
}

class AFailedRequestClient extends BaseClient {
  AFailedRequestClient(Client client, Hub hub)
      : _client = client,
        _hub = hub;

  final Client _client;
  final Hub _hub;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    int? statusCode;
    Object? exception;
    StackTrace? stackTrace;
    StreamedResponse? response;

    final stopwatch = Stopwatch();
    stopwatch.start();

    try {
      response = await _client.send(request);
      statusCode = response.statusCode;
      return response;
    } catch (e, st) {
      var newException = e;
      if (newException is ClientException) {
        var ddd = AHttpSanitizer.sanitizeUrl(newException.uri?.toString());
        newException = ClientException(newException.message, Uri.tryParse(ddd?.url ?? ""));
      }

      // SanityCheck where we check the exception for sensitive strings and replace exception if found
      var sExceptionString = ALogger().censorLogs(newException.toString());
      if (newException.toString() != sExceptionString) {
        newException = ClientException('${newException.runtimeType} $sExceptionString *censored*');
      }

      exception = newException;
      stackTrace = st;
      // Throw rewritten sanitised exception with same stack trace
      Error.throwWithStackTrace(newException, st);
    } finally {
      stopwatch.stop();
      await _captureEventIfNeeded(
        request,
        statusCode,
        exception,
        stackTrace,
        response,
        stopwatch.elapsed,
      );
    }
  }

  /// Because we dont control the server there is a massive amount of noise in these errors to filter out.

  Future<void> _captureEventIfNeeded(
      BaseRequest request, int? statusCode, Object? exception, StackTrace? stackTrace, StreamedResponse? response, Duration duration) async {
    if (exception == null) {
      return;
    }

    if (statusCode == 500) {
      // dont log on 500 because this is a server error and we dont control the error
      return;
    }

    for (final ignoredException in ignoredExceptions) {
      if (exception.toString().contains(ignoredException)) {
        // We dont capture these exceptions.
        return;
      }
    }

    final reason = 'HTTP Client Error with status code: $statusCode';

    await _captureEvent(
      exception: exception,
      stackTrace: stackTrace,
      request: request,
      requestDuration: duration,
      response: response,
      reason: reason,
    );
  }

  @override
  void close() => _client.close();

  // See https://develop.sentry.dev/sdk/event-payloads/request/
  Future<void> _captureEvent({
    required Object? exception,
    StackTrace? stackTrace,
    String? reason,
    required Duration requestDuration,
    required BaseRequest request,
    required StreamedResponse? response,
  }) async {
    final sentryRequest = SentryRequest.fromUri(
      method: request.method,
      headers: null,
      uri: replacementUriWithPath(request.url.path),
      data: {
        'content_length': request.contentLength.toString(),
        'duration': requestDuration.toString(),
      },
    );

    final mechanism = Mechanism(
      type: 'SentryHttpClient',
      description: reason,
    );

    bool? snapshot;

    if (exception is SentryHttpClientError) {
      snapshot = true;
    }

    final throwableMechanism = ThrowableMechanism(
      mechanism,
      exception,
      snapshot: snapshot,
    );

    final event = SentryEvent(
      throwable: throwableMechanism,
      request: sentryRequest,
      timestamp: _hub.options.clock(),
    );

    final hint = Hint.withMap({
      TypeCheckHint.httpRequest: sentryRequest,
    });

    if (response != null) {
      event.contexts.response = SentryResponse(
        headers: null,
        bodySize: response.contentLength,
        statusCode: response.statusCode,
      );
      hint.set(TypeCheckHint.httpResponse, response);
    }

    await _hub.captureEvent(
      event,
      stackTrace: stackTrace,
      hint: hint,
    );
  }
}

/// A [http](https://pub.dev/packages/http)-package compatible HTTP client
/// which adds support to Sentry Performance feature.
/// https://develop.sentry.dev/sdk/performance
class ATracingClient extends BaseClient {
  ATracingClient(Client client, Hub hub)
      : _hub = hub,
        _client = client;

  final Client _client;
  final Hub _hub;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // see https://develop.sentry.dev/sdk/performance/#header-sentry-trace

    final urlDetails = AHttpSanitizer.sanitizeUrl(request.url.toString());

    var description = request.method;
    if (urlDetails != null) {
      description += ' ${urlDetails.urlOrFallback}';
    }

    final currentSpan = _hub.getSpan();
    var span = currentSpan?.startChild(
      'http.client',
      description: description,
    );
    span?.origin = ASentryTraceOrigins.autoHttpHttp;

    // if the span is NoOp, we don't want to attach headers
    if (span is NoOpSentrySpan) {
      span = null;
    }

    span?.setData('http.request.method', request.method);
    urlDetails?.applyToSpan(span);

    StreamedResponse? response;
    try {
      if (span != null) {
        addSentryTraceHeaderFromSpan(span, request.headers);
        addBaggageHeaderFromSpan(
          span,
          request.headers,
        );
      } else {
        final scope = _hub.scope;
        final propagationContext = scope.propagationContext;

        final traceHeader = propagationContext.toSentryTrace();
        addSentryTraceHeader(traceHeader, request.headers);

        final baggage = propagationContext.baggage;
        if (baggage != null) {
          final baggageHeader = SentryBaggageHeader.fromBaggage(baggage);
          addBaggageHeader(baggageHeader, request.headers);
        }
      }

      response = await _client.send(request);
      span?.setData('http.response.status_code', response.statusCode);
      span?.setData('http.response_content_length', response.contentLength);
      span?.status = SpanStatus.fromHttpStatusCode(response.statusCode);
    } catch (exception) {
      span?.throwable = exception;
      span?.status = const SpanStatus.internalError();

      rethrow;
    } finally {
      await span?.finish();
    }
    return response;
  }

  @override
  void close() => _client.close();
}

class ABreadcrumbClient extends BaseClient {
  ABreadcrumbClient(Client client, Hub hub)
      : _hub = hub,
        _client = client;

  final Client _client;
  final Hub _hub;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // See https://develop.sentry.dev/sdk/event-payloads/breadcrumbs/

    var requestHadException = false;
    int? statusCode;
    String? reason;
    int? responseBodySize;

    final stopwatch = Stopwatch();
    stopwatch.start();

    try {
      final response = await _client.send(request);

      statusCode = response.statusCode;
      reason = response.reasonPhrase;
      responseBodySize = response.contentLength;

      return response;
    } catch (_) {
      requestHadException = true;
      rethrow;
    } finally {
      stopwatch.stop();

      final urlDetails = AHttpSanitizer.sanitizeUrl(request.url.toString()) ?? AUrlDetails();

      var breadcrumb = Breadcrumb.http(
        level: requestHadException ? SentryLevel.error : SentryLevel.info,
        url: Uri.parse(urlDetails.urlOrFallback),
        method: request.method,
        statusCode: statusCode,
        reason: reason,
        requestDuration: stopwatch.elapsed,
        requestBodySize: request.contentLength,
        responseBodySize: responseBodySize,
        httpQuery: urlDetails.query,
        httpFragment: urlDetails.fragment,
      );

      await _hub.addBreadcrumb(breadcrumb);
    }
  }

  @override
  void close() => _client.close();
}

class AHttpSanitizer {
  static final List<String> _securityHeaders = [
    "X-FORWARDED-FOR",
    "AUTHORIZATION",
    "COOKIE",
    "SET-COOKIE",
    "X-API-KEY",
    "X-REAL-IP",
    "REMOTE-ADDR",
    "FORWARDED",
    "PROXY-AUTHORIZATION",
    "X-CSRF-TOKEN",
    "X-CSRFTOKEN",
    "X-XSRF-TOKEN"
  ];

  /// Parse and sanitize url data for sentry.io
  static AUrlDetails? sanitizeUrl(String? url) {
    if (url == null) {
      return null;
    }
    final queryIndex = url.indexOf('?');
    final fragmentIndex = url.indexOf('#');

    if (queryIndex > -1 && fragmentIndex > -1 && fragmentIndex < queryIndex) {
      // url considered malformed because of fragment position
      return AUrlDetails();
    } else {
      try {
        final uri = Uri.parse(url);
        uri.queryParameters["token"] = "censored"; // Censor token in query parameters
        return AUrlDetails(
            url: "https://$replacementHost${uri.path}",
            query: uri.query.isEmpty ? null : uri.query,
            fragment: uri.fragment.isEmpty ? null : uri.fragment);
      } catch (_) {
        return null;
      }
    }
  }

  static Map<String, String>? sanitizedHeaders(Map<String, String>? headers) {
    if (headers == null) {
      return null;
    }
    final sanitizedHeaders = <String, String>{};
    headers.forEach((key, value) {
      if (!_securityHeaders.contains(key.toUpperCase())) {
        sanitizedHeaders[key] = value;
      }
    });
    return sanitizedHeaders;
  }
}

class AUrlDetails {
  AUrlDetails({this.url, this.query, this.fragment});

  final String? url;
  final String? query;
  final String? fragment;

  static const _unknown = 'unknown';

  late final urlOrFallback = Uri.tryParse(url ?? _unknown)?.toString() ?? _unknown;

  void applyToSpan(ISentrySpan? span) {
    if (span == null) {
      return;
    }
    if (url != null) {
      span.setData('url', url);
    }
    if (query != null) {
      span.setData("http.query", query);
    }
    if (fragment != null) {
      span.setData("http.fragment", fragment);
    }
  }
}

class ASentryTraceOrigins {
  static const manual = 'manual';

  static const autoNavigationRouteObserver = 'auto.navigation.route_observer';
  static const autoHttpHttp = 'auto.http.http';
  static const autoHttpDioHttpClientAdapter = 'auto.http.dio.http_client_adapter';
  static const autoHttpDioTransformer = 'auto.http.dio.transformer';
  static const autoFile = 'auto.file';
  static const autoFileAssetBundle = 'auto.file.asset_bundle';
  static const autoDbSqfliteOpenDatabase = 'auto.db.sqflite.open_database';
  static const autoDbSqfliteBatch = 'auto.db.sqflite.batch';
  static const autoDbSqfliteDatabase = 'auto.db.sqflite.database';
  static const autoDbSqfliteDatabaseExecutor = 'auto.db.sqflite.database_executor';
  static const autoDbSqfliteDatabaseFactory = 'auto.db.sqflite.database_factory';
  static const autoDbIsar = 'auto.db.isar';
  static const autoDbIsarCollection = 'auto.db.isar.collection';
  static const autoDbHive = 'auto.db.hive';
  static const autoDbHiveBoxBase = 'auto.db.hive.box_base';
  static const autoDbHiveLazyBox = 'auto.db.hive.lazy_box';
  static const autoDbHiveBoxCollection = 'auto.db.hive.box_collection';
  static const autoDbDriftQueryExecutor = 'auto.db.drift.query.executor';
  static const autoDbDriftTransactionExecutor = 'auto.db.drift.transaction.executor';
  static const autoUiTimeToDisplay = 'auto.ui.time_to_display';
  static const manualUiTimeToDisplay = 'manual.ui.time_to_display';
}
