// lib/firebase_options.dart - CON TUS DATOS REALES
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

  // ✅ USANDO TUS DATOS REALES de google-services.json
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKAQl97fpJ8AROD3kIu-2MjH6ELmzIK3Q',
    appId: '1:819697521102:web:PENDIENTE', // ⚠️ Necesitas crear app web
    messagingSenderId: '819697521102',
    projectId: 'habitiurs',
    authDomain: 'habitiurs.firebaseapp.com',
    storageBucket: 'habitiurs.firebasestorage.app',
    databaseURL: 'https://habitiurs-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKAQl97fpJ8AROD3kIu-2MjH6ELmzIK3Q',
    appId: '1:819697521102:android:9795e4fab473378b551b9f',
    messagingSenderId: '819697521102',
    projectId: 'habitiurs',
    storageBucket: 'habitiurs.firebasestorage.app',
    databaseURL: 'https://habitiurs-default-rtdb.europe-west1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKAQl97fpJ8AROD3kIu-2MjH6ELmzIK3Q',
    appId: '1:819697521102:ios:PENDIENTE', // ⚠️ Necesitas crear app iOS si planeas usarla
    messagingSenderId: '819697521102',
    projectId: 'habitiurs',
    storageBucket: 'habitiurs.firebasestorage.app',
    databaseURL: 'https://habitiurs-default-rtdb.europe-west1.firebasedatabase.app',
    iosClientId: '819697521102-4rpdp15lq4in3uho5sc8cdrrc29vvhs4.apps.googleusercontent.com',
    iosBundleId: 'com.example.habitiurs',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAKAQl97fpJ8AROD3kIu-2MjH6ELmzIK3Q',
    appId: '1:819697521102:ios:PENDIENTE',
    messagingSenderId: '819697521102',
    projectId: 'habitiurs',
    storageBucket: 'habitiurs.firebasestorage.app',
    databaseURL: 'https://habitiurs-default-rtdb.europe-west1.firebasedatabase.app',
    iosClientId: '819697521102-4rpdp15lq4in3uho5sc8cdrrc29vvhs4.apps.googleusercontent.com',
    iosBundleId: 'com.example.habitiurs',
  );
}