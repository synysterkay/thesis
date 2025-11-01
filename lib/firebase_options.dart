import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4lXSwpcLOUteTeTqMxiqT2Zx5sOumGYU',
    appId: '1:1098826060423:android:3f0226d2dd4fc3ddf05e22',
    messagingSenderId: '1098826060423',
    projectId: 'thesis-generator-web',
    storageBucket: 'thesis-generator-web.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7bAnM-URPBcwPEMfRZ47z1lkJpmE8AyI',
    appId: '1:1098826060423:ios:4a57fbcca138ff95f05e22',
    messagingSenderId: '1098826060423',
    projectId: 'thesis-generator-web',
    storageBucket: 'thesis-generator-web.firebasestorage.app',
    iosClientId:
        '1098826060423-73kddmjuao2m1rsnocpb2goicionifol.apps.googleusercontent.com',
    iosBundleId: 'com.thesis.generator.ai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBbErRqwrcX6-ogwmnmr98E3Q4H8KP4w9Q',
    appId: '1:1098826060423:web:7ee70dc121234297f05e22',
    messagingSenderId: '1098826060423',
    projectId: 'thesis-generator-web',
    authDomain: 'thesis-generator-web.firebaseapp.com',
    storageBucket: 'thesis-generator-web.firebasestorage.app',
    measurementId: 'G-BY0DNNV0K3',
  );
}
