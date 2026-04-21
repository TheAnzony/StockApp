// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class BetaFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Beta no tiene configuración web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'BetaFirebaseOptions no soporta esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCb3ZI_Pi_n7AyY6UeqKRazXCL6PYiVuWE',
    appId: '1:5799277496:android:0c885bc390ca02412d154d',
    messagingSenderId: '5799277496',
    projectId: 'stock-cachimbas-beta',
    storageBucket: 'stock-cachimbas-beta.firebasestorage.app',
  );
}
