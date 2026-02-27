import 'package:flutter/foundation.dart';

/// Maximum length for log messages before truncation
const int _maxLogLength = 1000000000;

/// Truncate long strings for logging
String _truncateLog(dynamic data) {
  if (data == null) return 'null';
  final String stringData = data.toString();
  if (stringData.length <= _maxLogLength) {
    return stringData;
  }
  return '${stringData.substring(0, _maxLogLength)}... [truncated ${stringData.length - _maxLogLength} characters]';
}

void logInfo(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Log info with automatic truncation for long data
void logInfoData(String label, dynamic data) {
  if (kDebugMode) {
    debugPrint('$label: ${_truncateLog(data)}');
  }
}

void logError(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint('Cause: ${_truncateLog(error)}');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}

/// Log error data with automatic truncation for long data
void logErrorData(String label, dynamic data) {
  if (kDebugMode) {
    debugPrint('ERROR: $label: ${_truncateLog(data)}');
  }
}

/// Log full response data without truncation (for debugging)
void logFullResponse(String label, dynamic data) {
  if (kDebugMode) {
    if (data == null) {
      debugPrint('$label: null');
      return;
    }

    try {
      // Try to format as JSON if it's a Map or List
      String dataString;
      if (data is Map || data is List) {
        // Convert to formatted string representation
        dataString = _formatData(data);
      } else {
        dataString = data.toString();
      }

      // Split into chunks if too long for single line, but don't truncate
      const int chunkSize = 2000; // Log in chunks of 2000 chars
      if (dataString.length <= chunkSize) {
        debugPrint('$label: $dataString');
      } else {
        debugPrint('$label:');
        for (int i = 0; i < dataString.length; i += chunkSize) {
          final end = (i + chunkSize < dataString.length)
              ? i + chunkSize
              : dataString.length;
          debugPrint(dataString.substring(i, end));
        }
      }
    } catch (e) {
      // Fallback to simple toString if formatting fails
      debugPrint('$label: ${data.toString()}');
    }
  }
}

/// Format data structure for readable logging
String _formatData(dynamic data, {int indent = 0}) {
  const indentStr = '  ';
  final currentIndent = indentStr * indent;

  if (data is Map) {
    if (data.isEmpty) return '{}';
    final buffer = StringBuffer();
    buffer.writeln('{');
    data.forEach((key, value) {
      buffer.write('$currentIndent$indentStr$key: ');
      if (value is Map || value is List) {
        buffer.writeln(_formatData(value, indent: indent + 1));
      } else {
        buffer.writeln(_formatValue(value));
      }
    });
    buffer.write('$currentIndent}');
    return buffer.toString();
  } else if (data is List) {
    if (data.isEmpty) return '[]';
    final buffer = StringBuffer();
    buffer.writeln('[');
    for (var i = 0; i < data.length; i++) {
      buffer.write('$currentIndent$indentStr[$i]: ');
      if (data[i] is Map || data[i] is List) {
        buffer.writeln(_formatData(data[i], indent: indent + 1));
      } else {
        buffer.writeln(_formatValue(data[i]));
      }
    }
    buffer.write('$currentIndent]');
    return buffer.toString();
  }
  return data.toString();
}

/// Format a single value for logging
String _formatValue(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return "'$value'";
  return value.toString();
}
