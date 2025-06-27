import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      print('✅ [Firebase] Initialized successfully');
    } catch (e) {
      print('⚠️ [Firebase] Failed to initialize: $e');
      rethrow;
    }
  }
  
  static bool get isInitialized => Firebase.apps.isNotEmpty;
}