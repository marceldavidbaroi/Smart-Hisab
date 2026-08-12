import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Central Error Handler managing uncaught framework errors, platform dispatch errors,
/// and explicit service/provider exception reporting.
class ErrorHandlerService {
  ErrorHandlerService._();

  /// Initialize global listeners for uncaught synchronous and asynchronous errors.
  static void initialize() {
    // Catch Flutter UI framework errors (rendering, layout, build phase exceptions)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logAndNotify(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework UI Error',
      );
    };

    // Catch unhandled asynchronous exceptions in the Dart isolate/event loop
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      _logAndNotify(
        error: error,
        stackTrace: stackTrace,
        context: 'Unhandled Async Error',
      );
      return true; // Prevents crash / unhandled bubble
    };
  }

  /// Explicitly handle caught errors in try-catch blocks across providers or services
  static void handleError(
    Object error, [
    StackTrace? stackTrace,
    String? userFriendlyMessage,
  ]) {
    _logAndNotify(
      error: error,
      stackTrace: stackTrace,
      context: 'Caught Error',
      customUserMessage: userFriendlyMessage,
    );
  }

  static void _logAndNotify({
    required Object error,
    StackTrace? stackTrace,
    required String context,
    String? customUserMessage,
  }) {
    // Debug logging for developer visibility
    debugPrint('🚨 [$context]: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString().split('\n').take(5).join('\n'));
    }

    // Extract user friendly message
    final String message = customUserMessage ?? _getUserFriendlyErrorMessage(error);

    // Notify user via global notification snackbar
    NotificationService.showError(message);
  }

  static String _getUserFriendlyErrorMessage(Object error) {
    final str = error.toString().toLowerCase();

    if (str.contains('socketexception') || str.contains('networkisunreachable') || str.contains('connection refused')) {
      return 'Network connection issue. Operations will sync automatically when back online.';
    }
    if (str.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (str.contains('unauthorized') || str.contains('invalid_grant') || str.contains('jwt')) {
      return 'Session expired. Please log in again.';
    }
    if (str.contains('format-exception')) {
      return 'Invalid data format encountered.';
    }

    // Fallback error message
    return error.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
  }
}
