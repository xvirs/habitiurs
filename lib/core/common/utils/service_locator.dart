import '../../di/injection_container.dart';

abstract class ServiceLocator {
  static T get<T>() => InjectionContainer().get<T>();
  
  static bool isRegistered<T>() => InjectionContainer().isRegistered<T>();
  
  static void ensureInitialized() {
    if (!InjectionContainer().isInitialized) {
      throw StateError(
        'InjectionContainer must be initialized before using ServiceLocator'
      );
    }
  }
}