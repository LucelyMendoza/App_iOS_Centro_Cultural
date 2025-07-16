// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD...v8E', // Reemplaza con tu API Key real
    appId: '1:176276096987:android:3c45e9057fb6ab85d149fe',
    messagingSenderId: '176276096987',
    projectId: 'beaconlocalization',
    storageBucket: 'beaconlocalization.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD...v8E', // Usa la misma API Key o una específica para iOS
    appId: '1:176276096987:ios:3c45e9057fb6ab85d149fe', // Mismo App ID
    messagingSenderId: '176276096987',
    projectId: 'beaconlocalization',
    storageBucket: 'beaconlocalization.appspot.com',
    iosBundleId: 'com.example.miApp', // Reemplaza con tu Bundle ID de iOS
  );
}
