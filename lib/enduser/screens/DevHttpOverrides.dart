import 'dart:io';

/// Bypasses SSL certificate verification for the dev server IP.
/// ⚠️ Use ONLY for development/staging — never in production.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        // Allow all hosts in development
        return true;
      };
  }
}