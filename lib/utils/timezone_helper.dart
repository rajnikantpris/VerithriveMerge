import 'dart:io';

/// Helper class to get IANA timezone identifier
class TimezoneHelper {
  /// Get the current IANA timezone identifier
  /// Returns timezone in format like "Asia/Kolkata", "America/New_York", etc.
  static String getCurrentTimezone() {
    try {
      // Get the timezone offset and name
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      final offset = now.timeZoneOffset;

      // Try to determine IANA timezone from offset and name
      // This is a simplified approach - for production, consider using
      // a package like 'timezone' or 'flutter_native_timezone'
      
      // Common timezone mappings based on offset and name
      // This is a basic implementation - you may want to enhance it
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, we can use platform channels
        // For now, use a simple mapping based on common timezones
        return _getTimezoneFromOffset(offset, timeZoneName);
      } else {
        // For other platforms, use offset-based detection
        return _getTimezoneFromOffset(offset, timeZoneName);
      }
    } catch (e) {
      // Fallback to UTC if detection fails
      return 'UTC';
    }
  }

  /// Get timezone from offset and name (simplified mapping)
  static String _getTimezoneFromOffset(Duration offset, String timeZoneName) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes % 60;
    
    // Common timezone mappings
    // Note: This is a simplified approach. For production, consider using
    // a proper timezone database or package like 'timezone' or 'flutter_native_timezone'
    
    // Try to infer from timezone name abbreviation first (more reliable)
    final tzNameUpper = timeZoneName.toUpperCase();
    if (tzNameUpper.contains('IST') && hours == 5 && minutes == 30) {
      return 'Asia/Kolkata';
    } else if (tzNameUpper.contains('GMT') || tzNameUpper.contains('UTC')) {
      return 'UTC';
    } else if (tzNameUpper.contains('EST') || tzNameUpper.contains('EDT')) {
      return 'America/New_York';
    } else if (tzNameUpper.contains('PST') || tzNameUpper.contains('PDT')) {
      return 'America/Los_Angeles';
    } else if (tzNameUpper.contains('CST') || tzNameUpper.contains('CDT')) {
      // CST can be Central Standard Time (US) or China Standard Time
      if (hours == -6 || hours == -5) {
        return 'America/Chicago';
      } else if (hours == 8) {
        return 'Asia/Shanghai';
      }
    } else if (tzNameUpper.contains('MST') || tzNameUpper.contains('MDT')) {
      return 'America/Denver';
    }
    
    // India Standard Time (IST) - UTC+5:30
    if (hours == 5 && minutes == 30) {
      return 'Asia/Kolkata';
    }
    
    // Common timezone offsets
    switch (hours) {
      case 0:
        if (minutes == 0) return 'UTC';
        break;
      case 1:
        return 'Europe/Paris'; // CET
      case 2:
        return 'Europe/Berlin'; // CEST
      case 5:
        if (minutes == 30) return 'Asia/Kolkata'; // IST
        return 'Asia/Karachi'; // PKT
      case 8:
        return 'Asia/Shanghai'; // CST
      case 9:
        return 'Asia/Tokyo'; // JST
      case -5:
        return 'America/New_York'; // EST/EDT
      case -6:
        return 'America/Chicago'; // CST/CDT
      case -7:
        return 'America/Denver'; // MST/MDT
      case -8:
        return 'America/Los_Angeles'; // PST/PDT
      case 10:
        return 'Australia/Sydney'; // AEDT
    }
    
    // For unknown timezones, return UTC as fallback
    // In production, you should use a proper timezone package
    // like 'timezone' or 'flutter_native_timezone' for accurate IANA timezone detection
    return 'UTC';
  }
}

