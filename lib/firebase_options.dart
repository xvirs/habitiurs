// lib/firebase_options.dart - CONFIGURACIÓN MANUAL
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // 🔥 REEMPLAZA ESTOS VALORES con los de tu proyecto Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY_WEB',
    appId: 'TU_APP_ID_WEB',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    authDomain: 'TU_PROJECT_ID.firebaseapp.com',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: 'TU_APP_ID_ANDROID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
    iosClientId: 'TU_IOS_CLIENT_ID',
    iosBundleId: 'com.example.habitiurs',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
    iosClientId: 'TU_IOS_CLIENT_ID',
    iosBundleId: 'com.example.habitiurs',
  );
}

// 📝 INSTRUCCIONES PARA ENCONTRAR TUS VALORES:
// 1. Ve a Firebase Console → Project Settings
// 2. Scroll down a "Your apps"
// 3. Click en tu app Android/iOS
// 4. Los valores están en "SDK setup and configuration"