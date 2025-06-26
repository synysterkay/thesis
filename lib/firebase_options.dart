import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCrwRYgtoLrEagqb2m-E1VOocxNr-9By30',
    appId: '1:153965444638:android:7f3a717c504bb5f471780f',
    messagingSenderId: '153965444638',
    projectId: 'thesis-generator-2024',
    storageBucket: 'thesis-generator-2024.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzUnNezUdzqCDVQ32Nl15b_osug350jU4',
    appId: '1:153965444638:ios:dab9894438d1527771780f',
    messagingSenderId: '153965444638',
    projectId: 'thesis-generator-2024',
    storageBucket: 'thesis-generator-2024.firebasestorage.app',
    iosBundleId: 'com.thesis.generator.ai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAgqosyJt30acT9hCwmHFRudeYoeHmu-1o',
    appId: '1:153965444638:web:bd46afd4bd40926471780f',
    messagingSenderId: '153965444638',
    projectId: 'thesis-generator-2024',
    authDomain: 'thesis-generator-2024.firebaseapp.com',
    storageBucket: 'thesis-generator-2024.firebasestorage.app',
  );

}