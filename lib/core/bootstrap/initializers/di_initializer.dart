import '../../di/injection_container.dart';

class DIInitializer {
  static Future<void> initialize() async {
    final container = InjectionContainer();
    await container.init();
    print('✅ [DI] Dependencies initialized');
  }
  
  static Future<void> dispose() async {
    final container = InjectionContainer();
    await container.dispose();
    print('🧹 [DI] Dependencies disposed');
  }
}