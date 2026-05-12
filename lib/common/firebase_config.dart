import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

/// Common Firebase configuration class for Android and iOS
class FirebaseConfig {
  // Common Firebase project information
  // static const String _projectId = 'verithrive-5380e';
  static const String _projectId = 'verithrive---app---prod';
  // static const String _messagingSenderId = '616853878729';
  static const String _messagingSenderId = '950187352283';
  // static const String _storageBucket = 'verithrive-5380e.firebasestorage.app';
  static const String _storageBucket = 'verithrive---app---prod.firebasestorage.app';

  // Android configuration
  // static const String _androidApiKey =
  //     'AIzaSyDjdom-8K5VyqYV_zFUtPX_Zabk3r-C6XQ';

  static const String _androidApiKey =
      'AIzaSyA3bLE4gYWARW3FoaNTtNYbuxgDeSsqRH0';

  // static const String _androidAppId =
  //     '1:616853878729:android:981ded7c32ec4320e25a18';

  static const String _androidAppId =
      '1:950187352283:android:70b6e4be572a3882ac6cfe';

  // iOS configuration
  // TODO: Update these values when you have GoogleService-Info.plist for iOS
  static const String _iosApiKey =
      'AIzaSyBbVbb_af4GqIHHjVCRsx37fJpuL73-5n8'; // Same API key or get from iOS config
  static const String _iosAppId =
      '1:38374486736:ios:b589d4e8890c404d9264d5'; // Replace with actual iOS app ID
  static const String _iosBundleId =
      'com.app.verithrive.professional.verithrive'; // Replace with actual iOS bundle ID

  /// Get Firebase options based on the current platform
  static FirebaseOptions getFirebaseOptions() {
    if (Platform.isAndroid) {
      return getAndroidOptions();
    } else if (Platform.isIOS) {
      return getIOSOptions();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// Get Firebase options for Android
  static FirebaseOptions getAndroidOptions() {
    return const FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
    );
  }

  /// Get Firebase options for iOS
  static FirebaseOptions getIOSOptions() {
    return const FirebaseOptions(
      apiKey: _iosApiKey,
      appId: _iosAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      iosBundleId: _iosBundleId,
    );
  }
}
