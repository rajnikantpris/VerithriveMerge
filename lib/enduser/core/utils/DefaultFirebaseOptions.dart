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

  // Production

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3bLE4gYWARW3FoaNTtNYbuxgDeSsqRH0',
    appId: '1:950187352283:android:70b6e4be572a3882ac6cfe',
    messagingSenderId: '950187352283',
    projectId: 'verithrive---app---prod',
  );

  // Development
  //
  // static const FirebaseOptions android = FirebaseOptions(
  //   apiKey: 'AIzaSyDjdom-8K5VyqYV_zFUtPX_Zabk3r-C6XQ',
  //   appId: '1:616853878729:android:981ded7c32ec4320e25a18',
  //   messagingSenderId: '616853878729',
  //   projectId: 'verithrive-5380e',
  // );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3bLE4gYWARW3FoaNTtNYbuxgDeSsqRH0',
    appId: '1:950187352283:android:70b6e4be572a3882ac6cfe',
    messagingSenderId: '950187352283',
    projectId: 'verithrive---app---prod',
    androidClientId: '38374486736-mm3o9np8ra0h6mtr6q9i4gbvklglua8d.apps.googleusercontent.com',
    iosClientId: '',
    iosBundleId: '',
  );
}