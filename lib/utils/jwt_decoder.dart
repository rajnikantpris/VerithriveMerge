import 'dart:convert';

/// Utility class for decoding JWT tokens
class JwtDecoder {
  /// Decode JWT token and return the payload as a Map
  /// Returns null if token is invalid or cannot be decoded
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      // Decode base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extract email from JWT token
  static String? getEmail(String token) {
    final payload = decode(token);
    return payload?['email'] as String?;
  }

  /// Extract subject (user ID) from JWT token
  static String? getSubject(String token) {
    final payload = decode(token);
    return payload?['sub'] as String?;
  }
}

