import 'package:firebase_analytics/firebase_analytics.dart';

/// Servicio central de Firebase Analytics.
///
/// La instrumentación automática (first_open, session_start, screen_view,
/// usuarios activos, retención) la aportan el SDK y el [observer] de
/// navegación enganchado en el MaterialApp. Acá viven además los eventos
/// propios del producto.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Observer para registrar `screen_view` automáticamente al navegar.
  late final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  /// Habilita la recolección (idempotente). Se llama en el bootstrap.
  Future<void> init() async {
    try {
      await analytics.setAnalyticsCollectionEnabled(true);
    } catch (_) {
      // Nunca romper el arranque por Analytics.
    }
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await analytics.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  Future<void> logLogin(String method) async {
    try {
      await analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> onboardingCompleted() => _log('onboarding_completed');
  Future<void> habitCreated() => _log('habit_created');
  Future<void> habitChecked() => _log('habit_checked');
  Future<void> missionCreated({required bool hasDueDate}) =>
      _log('mission_created', {'has_due_date': hasDueDate ? 1 : 0});
  Future<void> missionCompleted() => _log('mission_completed');
  Future<void> aiRecommendation() => _log('ai_recommendation');
}
