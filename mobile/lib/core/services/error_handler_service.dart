import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_modal_bottom_sheet.dart';

/// Central Error Handler managing uncaught framework errors, platform dispatch errors,
/// and explicit service/provider exception reporting. Displays errors in an app-wide modal dialog.
class ErrorHandlerService {
  ErrorHandlerService._();

  /// Global key attached to MaterialApp's navigatorKey to show error dialogs/sheets
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Flag to prevent popping up duplicate modal dialogs simultaneously
  static bool _isDialogShowing = false;

  /// Initialize global listeners for uncaught synchronous and asynchronous errors.
  static void initialize() {
    // Catch Flutter UI framework errors (rendering, layout, build phase exceptions)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Suppress secondary framework assertions regarding Navigator debugLocked state
      if (details.exception.toString().contains('_debugLocked')) return;

      _logAndNotify(
        error: details.exception,
        stackTrace: details.stack,
        contextName: 'Flutter Framework UI Error',
      );
    };

    // Catch unhandled asynchronous exceptions in the Dart isolate/event loop
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      if (error.toString().contains('_debugLocked')) return true;

      _logAndNotify(
        error: error,
        stackTrace: stackTrace,
        contextName: 'Unhandled Async Error',
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
      contextName: 'Caught Error',
      customUserMessage: userFriendlyMessage,
    );
  }

  /// Checks standardized API / RPC response maps for `{ "success": false, "error": { ... } }`.
  /// Returns true if an error response was detected and handled by opening the error dialog.
  static bool handleApiResponse(dynamic response, [String? contextName]) {
    if (response is Map<String, dynamic>) {
      if (response['success'] == false) {
        final errorObj = response['error'];
        String errorMessage = 'Request failed.';
        String? errorCode;

        if (errorObj is Map<String, dynamic>) {
          errorMessage = errorObj['message'] as String? ?? errorObj['code'] as String? ?? errorMessage;
          errorCode = errorObj['code'] as String?;
        } else if (errorObj != null) {
          errorMessage = errorObj.toString();
        }

        showErrorDialog(
          message: errorMessage,
          title: contextName ?? 'API Error',
          details: errorCode != null ? 'Code: $errorCode\nResponse: $response' : 'Response: $response',
        );
        return true;
      }
    }
    return false;
  }

  static void _logAndNotify({
    required Object error,
    StackTrace? stackTrace,
    required String contextName,
    String? customUserMessage,
  }) {
    // Debug logging for developer visibility
    debugPrint('🚨 [$contextName]: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString().split('\n').take(5).join('\n'));
    }

    final String message = customUserMessage ?? _getUserFriendlyErrorMessage(error);

    showErrorDialog(
      message: message,
      title: contextName,
      details: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// Displays an app-wide Modal Bottom Sheet Error Dialog complying with project design guidelines
  static void showErrorDialog({
    required String message,
    String title = 'An Error Occurred',
    String? details,
    String? stackTrace,
  }) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null || _isDialogShowing) return;

    // Schedule modal presentation after current frame completes to avoid Navigator lock assertions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNavContext = navigatorKey.currentContext;
      if (currentNavContext == null || _isDialogShowing) return;

      _isDialogShowing = true;

      CustomModalBottomSheet.show(
        context: currentNavContext,
        title: title,
        child: _ErrorModalContent(
          message: message,
          details: details,
          stackTrace: stackTrace,
        ),
      ).whenComplete(() {
        _isDialogShowing = false;
      });
    });
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

class _ErrorModalContent extends StatefulWidget {
  final String message;
  final String? details;
  final String? stackTrace;

  const _ErrorModalContent({
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  State<_ErrorModalContent> createState() => _ErrorModalContentState();
}

class _ErrorModalContentState extends State<_ErrorModalContent> {
  bool _showTechnicalDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgDetailColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSubColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.danger,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User-friendly message
          Text(
            widget.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Toggle Technical Details if available
          if (widget.details != null || widget.stackTrace != null) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _showTechnicalDetails = !_showTechnicalDetails;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showTechnicalDetails ? 'Hide technical details' : 'Show technical details',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSubColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showTechnicalDetails ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 16,
                      color: textSubColor,
                    ),
                  ],
                ),
              ),
            ),
            if (_showTechnicalDetails) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgDetailColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '${widget.details ?? ""}\n\n${widget.stackTrace ?? ""}'.trim(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: textSubColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Dismiss action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Dismiss',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

