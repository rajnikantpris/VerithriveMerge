import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {

  static FirebaseOptions get currentPlatform {

    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.fuchsia:
        // TODO: Handle this case.
      case TargetPlatform.linux:
        // TODO: Handle this case.
      case TargetPlatform.macOS:
        // TODO: Handle this case.
      case TargetPlatform.windows:
        // TODO: Handle this case.
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );

  }


  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIHdFq55OMUeaBaKgsAB1Cpi5r5vEFU8k',
    appId: '1:38374486736:android:87b926dcfe555b7c9264d5',
    messagingSenderId: '38374486736',
    projectId: 'verithrive-31bd6',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIHdFq55OMUeaBaKgsAB1Cpi5r5vEFU8k',
    appId: '1:38374486736:android:87b926dcfe555b7c9264d5',
    messagingSenderId: '38374486736',
    projectId: 'verithrive-31bd6',
    androidClientId: '38374486736-mm3o9np8ra0h6mtr6q9i4gbvklglua8d.apps.googleusercontent.com',
    iosClientId: '',
    iosBundleId: '',
  );
}