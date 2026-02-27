import 'package:get/get.dart';

import '../api/api_response.dart';
import '../utils/logger.dart';

/// Basic page states handled by all screens.
enum PageState { idle, loading, loadingShimmer, success, error }

class BaseController extends GetxController {
  /// Tracks the current page state (loading/error/etc).
  final pageState = PageState.idle.obs;

  /// Holds an error message to show on the UI.
  final errorMessage = ''.obs;

  /// Optional info message for callers that want to surface non-error text.
  final message = ''.obs;

  /// Shortcut setters for common states.
  void showLoading() => pageState(PageState.loading);
  void showShimmer() => pageState(PageState.loadingShimmer);

  void setSuccess() {
    pageState(PageState.success);
    errorMessage('');
  }

  void setError(String value) {
    pageState(PageState.error);
    errorMessage(value);
  }

  void resetState() {
    pageState(PageState.idle);
    errorMessage('');
    message('');
  }

  /// Convenience wrapper to handle async calls with optional lifecycle hooks.
  Future<T?> callDataService<T>(
    Future<T> future, {
    void Function()? onStart,
    void Function(T data)? onSuccess,
    void Function(Object error, StackTrace stack)? onError,
    void Function()? onComplete,
    bool showLoader = false,
    bool useShimmer = false,
    String Function(Object error)? mapErrorMessage,
  }) async {
    if (onStart != null) {
      onStart();
    }

    if (showLoader) showLoading();
    if (useShimmer) showShimmer();

    try {
      final result = await future;
      // Don't set success state if using loader - let finally block handle it
      if (!showLoader && !useShimmer) {
        setSuccess();
      }
      onSuccess?.call(result);
      return result;
    } catch (error, stack) {
      logError('Request failed', error: error, stackTrace: stack);
      final msg = mapErrorMessage?.call(error) ?? mapErrorToMessage(error);
      // Set error message for onError callback, but don't change pageState if using loader
      errorMessage(msg);
      if (!showLoader && !useShimmer) {
        setError(msg);
      }
      onError?.call(error, stack);
    } finally {
      if (onComplete != null) {
        onComplete();
      } else if (showLoader || useShimmer) {
        // Reset back to idle when default loaders were used.
        pageState(PageState.idle);
      }
    }
    return null;
  }

  /// Default error -> message mapper. Override in subclasses if needed.
  String mapErrorToMessage(Object error) {
    final value = error.toString();
    if (value.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (value.toLowerCase().contains('network') ||
        value.toLowerCase().contains('socket')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Check if error dialog was already shown (e.g., for connection timeouts)
  /// Returns true if dialog should be skipped
  bool shouldSkipErrorDialog(Object error, String errorMessage) {
    // Skip if error is ApiResponse with errorDialogShown flag
    if (error is ApiResponse && error.errorDialogShown) {
      return true;
    }
    // Skip if error message is "Server Not Working" (already shown in interceptor)
    if (errorMessage == 'Server Not Working') {
      return true;
    }
    return false;
  }
}
