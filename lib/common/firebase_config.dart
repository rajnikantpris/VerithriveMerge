import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

/// Common Firebase configuration class for Android and iOS
class FirebaseConfig {
  // Common Firebase project information
  static const String _projectId = 'verithrive-31bd6';
  static const String _messagingSenderId = '38374486736';
  static const String _storageBucket = 'verithrive-31bd6.firebasestorage.app';

  // Android configuration
  static const String _androidApiKey =
      'AIzaSyDIHdFq55OMUeaBaKgsAB1Cpi5r5vEFU8k';
  static const String _androidAppId =
      '1:38374486736:android:61f63046006e9c099264d5';

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
