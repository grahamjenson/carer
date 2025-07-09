import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/utils/logs.dart';
import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  static final ToastService _singleton = ToastService._();
  factory ToastService() => _singleton;

  ToastService._();
  final Map<String, ToastificationItem> _toasts = {};

  // Stopping the same error flodding the screen with cascading errors
  void showError(String msg, {String? description}) {
    if (AppLifecycleService().wasResumed2SecondsAgo) {
      // Dont show errors for the first 2 seconds
      return;
    }

    if (!AppLifecycleService().stateResumed) {
      // Dont show errors if the app is not resumed
      return;
    }

    if (_toasts[msg] != null) {
      return;
    }
    _toasts.remove(msg);

    Widget? descriptionWidget;
    if (description != null) {
      descriptionWidget = Text(description);
    }
    try {
      ToastificationItem ti = toastification.show(
        title: Text(msg),
        description: descriptionWidget,
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 5),
        callbacks: ToastificationCallbacks(
          onCloseButtonTap: (value) {
            toastification.dismiss(value);
            _toasts.remove(msg);
          },
          onDismissed: (value) => _toasts.remove(msg),
          onAutoCompleteCompleted: (toastItem) => _toasts.remove(msg),
        ),
      );

      _toasts[msg] = ti;
    } catch (e) {
      // If the toastification fails, we don't want to crash the app
      alog("Toastification Error Error: $e");
    }
  }

  void showSuccess(String msg, {String? description}) {
    Widget? descriptionWidget;
    if (description != null) {
      descriptionWidget = Text(description);
    }
    try {
      toastification.show(
        title: Text(msg),
        showProgressBar: false,
        description: descriptionWidget,
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 5),
      );
    } catch (e) {
      // If the toastification fails, we don't want to crash the app
      alog("Toastification Success Error: $e");
    }
  }
}
