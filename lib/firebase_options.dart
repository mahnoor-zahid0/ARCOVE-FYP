// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCrVqBVFb1OnQgRO4705dkgDeOuhbLyE3U',
    appId: '1:12204141211:web:cabfb57b8a9ecb3b51b43e',
    messagingSenderId: '12204141211',
    projectId: 'sample1-68403',
    authDomain: 'sample1-68403.firebaseapp.com',
    storageBucket: 'sample1-68403.appspot.com',
    measurementId: 'G-BQ17J3GVJF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhIbZeYe8XTCY4PfbQcid45X_T-vHKTG8',
    appId: '1:12204141211:android:2f42c9a7492bf7ad51b43e',
    messagingSenderId: '12204141211',
    projectId: 'sample1-68403',
    storageBucket: 'sample1-68403.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXSGlChSzy6lp43aH9XcFMs38wNhQYMS4',
    appId: '1:12204141211:ios:40c8e057c6ed3b2751b43e',
    messagingSenderId: '12204141211',
    projectId: 'sample1-68403',
    storageBucket: 'sample1-68403.appspot.com',
    iosBundleId: 'com.example.sample',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCXSGlChSzy6lp43aH9XcFMs38wNhQYMS4',
    appId: '1:12204141211:ios:40c8e057c6ed3b2751b43e',
    messagingSenderId: '12204141211',
    projectId: 'sample1-68403',
    storageBucket: 'sample1-68403.appspot.com',
    iosBundleId: 'com.example.sample',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCrVqBVFb1OnQgRO4705dkgDeOuhbLyE3U',
    appId: '1:12204141211:web:3846e4bd2638eb8c51b43e',
    messagingSenderId: '12204141211',
    projectId: 'sample1-68403',
    authDomain: 'sample1-68403.firebaseapp.com',
    storageBucket: 'sample1-68403.appspot.com',
    measurementId: 'G-FSSP6LDRTR',
  );

}