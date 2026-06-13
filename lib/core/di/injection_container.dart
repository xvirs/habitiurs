// lib/core/di/injection_container.dart
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;

// Core
import '../database/database_helper.dart';
import '../ai/repositories/ai_repository.dart';
import '../auth/services/auth_service.dart';
import '../auth/interfaces/i_auth_service.dart';
import '../sync/services/firebase_service.dart';
import '../sync/services/sync_manager.dart';
import '../sync/repositories/sync_repository.dart'; // Importa la interfaz

// Auth
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/usecases/check_auth_status.dart';
import '../../features/auth/domain/usecases/create_guest_session.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/logout_user.dart';

// Habits
import '../../features/habits/data/datasources/habit_local_datasource.dart';
import '../../features/habits/data/repositories/habit_repository_impl.dart';
import '../../features/habits/domain/repositories/habit_repository.dart';
import '../../features/habits/domain/usecases/create_habit.dart';
import '../../features/habits/domain/usecases/delete_habit.dart';
import '../../features/habits/domain/usecases/get_all_habits.dart';
import '../../features/habits/domain/usecases/get_week_entries.dart';
import '../../features/habits/domain/usecases/toggle_habit_entry.dart';
import '../../features/habits/domain/usecases/update_past_habit_entry.dart';
import '../../features/habits/domain/usecases/update_habit.dart';
import '../../features/habits/presentation/bloc/habit_bloc.dart';
import '../../features/habits/presentation/bloc/habit_evaluation_cubit.dart';

// Statistics
import '../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_current_month_statistics.dart';
import '../../features/statistics/domain/usecases/get_current_year_statistics.dart';
import '../../features/statistics/domain/usecases/get_historical_data.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';

// AI Assistant
import '../../features/ai_assistant/data/datasources/offline_content_datasource.dart';
import '../../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import '../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../../features/ai_assistant/domain/usecases/get_educational_content.dart';
import '../../features/ai_assistant/domain/usecases/get_app_guides.dart';
import '../../features/ai_assistant/domain/usecases/get_ai_recommendation.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

// Settings
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/update_settings.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  // Core Services
  late final DatabaseHelper _databaseHelper;
  late final AIRepository _aiRepository;
  late final IAuthService _authService;
  late final FirebaseService _firebaseService;
  late final SyncManager _syncManager;
  late final SyncRepository
  _syncRepository; // Se declara la interfaz del repositorio de sincronización

  // DataSources
  late final HabitLocalDataSource _habitLocalDataSource;
  late final StatisticsLocalDatasource _statisticsLocalDatasource;
  late final OfflineContentDatasource _offlineContentDatasource;
  late final SettingsLocalDatasource _settingsLocalDatasource;

  // Repositories
  late final HabitRepository _habitRepository;
  late final StatisticsRepository _statisticsRepository;
  late final AIAssistantRepository _aiAssistantRepository;
  late final SettingsRepository _settingsRepository;

  // Auth Use Cases
  late final CheckAuthStatus _checkAuthStatus;
  late final CreateGuestSession _createGuestSession;
  late final LoginWithGoogle _loginWithGoogle;
  late final LogoutUser _logoutUser;

  // Habits Use Cases
  late final GetAllHabits _getAllHabits;
  late final CreateHabit _createHabit;
  late final GetWeekEntries _getWeekEntries;
  late final ToggleHabitEntry _toggleHabitEntry;
  late final UpdatePastHabitEntry _updatePastHabitEntry;
  late final UpdateHabit _updateHabit;
  late final DeleteHabit _deleteHabit; // Se declara el use case de eliminación

  // Statistics Use Cases
  late final GetCurrentMonthStatistics _getCurrentMonthStatistics;
  late final GetCurrentYearStatistics _getCurrentYearStatistics;
  late final GetHistoricalData _getHistoricalData;

  // AI Assistant Use Cases
  late final GetEducationalContent _getEducationalContent;
  late final GetAppGuides _getAppGuides;
  late final GetAIRecommendation _getAIRecommendation;

  // Settings Use Cases
  late final GetSettings _getSettings;
  late final UpdateSettings _updateSettings;

  // BLoC singletons (una sola instancia compartida con el árbol de widgets)
  late final HabitBloc _habitBloc;
  late final StatisticsBloc _statisticsBloc;
  late final AIAssistantBloc _aiAssistantBloc;
  late final HabitEvaluationCubit _habitEvaluationCubit;
  late final SettingsBloc _settingsBloc;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _initializeFirebase();
      await _initializeCoreServices();
      _initializeRepositories();
      _initializeUseCases();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    _databaseHelper = SqliteDatabaseHelper();
    await _databaseHelper.database;

    await _initializeDataSources();

    _aiRepository = AIRepository();

    _authService = AuthService();
    await _authService.initGuestSession();

    _firebaseService = FirebaseService();

    // SyncManager: instancia única compartida
    _syncManager = SyncManager(
      firebaseService: _firebaseService,
      authService: _authService,
      habitDataSource: _habitLocalDataSource,
      statisticsDataSource: _statisticsLocalDatasource,
    );

    // SyncRepository reutiliza la misma instancia de SyncManager
    _syncRepository = SyncRepositoryImpl(
      syncManager: _syncManager,
      firebaseService: _firebaseService,
      authService: _authService,
    );
  }

  Future<void> _initializeDataSources() async {
    _habitLocalDataSource = HabitLocalDataSourceImpl(_databaseHelper);
    _statisticsLocalDatasource = StatisticsLocalDatasourceImpl(
      databaseHelper: _databaseHelper,
    );
    _offlineContentDatasource = OfflineContentDatasourceImpl();

    // Inicializar SharedPreferences para Settings
    final sharedPreferences = await SharedPreferences.getInstance();
    _settingsLocalDatasource = SettingsLocalDatasourceImpl(
      sharedPreferences: sharedPreferences,
    );
  }

  void _initializeRepositories() {
    _habitRepository = HabitRepositoryImpl(
      _habitLocalDataSource,
      _syncRepository, // Se inyecta la instancia del repositorio de sincronización
    );

    _statisticsRepository = StatisticsRepositoryImpl(
      localDatasource: _statisticsLocalDatasource,
    );

    _aiAssistantRepository = AIAssistantRepositoryImpl(
      offlineContentDatasource: _offlineContentDatasource,
      aiRepository: _aiRepository,
      habitRepository: _habitRepository,
    );

    _settingsRepository = SettingsRepositoryImpl(
      localDatasource: _settingsLocalDatasource,
    );
  }

  void _initializeUseCases() {
    _initializeAuthUseCases();
    _initializeHabitsUseCases();
    _initializeStatisticsUseCases();
    _initializeAIAssistantUseCases();
    _initializeSettingsUseCases();
    _initializeBlocs();
  }

  void _initializeBlocs() {
    _habitBloc = HabitBloc(
      getAllHabits: _getAllHabits,
      createHabit: _createHabit,
      getWeekEntries: _getWeekEntries,
      toggleHabitEntry: _toggleHabitEntry,
      updatePastHabitEntry: _updatePastHabitEntry,
      updateHabit: _updateHabit,
      deleteHabit: _deleteHabit,
    );
    _statisticsBloc = StatisticsBloc(
      getCurrentMonthStatistics: _getCurrentMonthStatistics,
      getCurrentYearStatistics: _getCurrentYearStatistics,
      getHistoricalData: _getHistoricalData,
      syncRepository: _syncRepository,
    );
    _aiAssistantBloc = AIAssistantBloc(
      getEducationalContent: _getEducationalContent,
      getAppGuides: _getAppGuides,
      getAIRecommendation: _getAIRecommendation,
    );
    _habitEvaluationCubit = HabitEvaluationCubit(aiRepository: _aiRepository);
    _settingsBloc = SettingsBloc(
      getSettings: _getSettings,
      updateSettings: _updateSettings,
    );
  }

  void _initializeAuthUseCases() {
    _checkAuthStatus = CheckAuthStatus(_authService);
    _createGuestSession = CreateGuestSession(_authService);
    _loginWithGoogle = LoginWithGoogle(_authService);
    _logoutUser = LogoutUser(_authService);
  }

  void _initializeHabitsUseCases() {
    _getAllHabits = GetAllHabits(_habitRepository);
    _createHabit = CreateHabit(_habitRepository);
    _updateHabit = UpdateHabit(_habitRepository);
    _getWeekEntries = GetWeekEntries(_habitRepository);
    _toggleHabitEntry = ToggleHabitEntry(_habitRepository);
    _updatePastHabitEntry = UpdatePastHabitEntry(_habitRepository);
    _deleteHabit = DeleteHabit(
      _habitRepository,
      _authService,
    ); // Se inyecta el servicio de autenticación
  }

  void _initializeStatisticsUseCases() {
    _getCurrentMonthStatistics = GetCurrentMonthStatistics(
      _statisticsRepository,
    );
    _getCurrentYearStatistics = GetCurrentYearStatistics(_statisticsRepository);
    _getHistoricalData = GetHistoricalData(_statisticsRepository);
  }

  void _initializeAIAssistantUseCases() {
    _getEducationalContent = GetEducationalContent(_aiAssistantRepository);
    _getAppGuides = GetAppGuides(_aiAssistantRepository);
    _getAIRecommendation = GetAIRecommendation(_aiAssistantRepository);
  }

  void _initializeSettingsUseCases() {
    _getSettings = GetSettings(_settingsRepository);
    _updateSettings = UpdateSettings(_settingsRepository);
  }

  // BLoC Getters
  AuthBloc get authBloc => AuthBloc(
    checkAuthStatus: _checkAuthStatus,
    createGuestSession: _createGuestSession,
    loginWithGoogle: _loginWithGoogle,
    logoutUser: _logoutUser,
  );

  HabitBloc get habitBloc => _habitBloc;
  StatisticsBloc get statisticsBloc => _statisticsBloc;
  AIAssistantBloc get aiAssistantBloc => _aiAssistantBloc;
  HabitEvaluationCubit get habitEvaluationCubit => _habitEvaluationCubit;
  SettingsBloc get settingsBloc => _settingsBloc;

  // Core Service Getters
  AIRepository get aiRepository => _aiRepository;
  IAuthService get authService => _authService;
  SyncRepository get syncRepository => _syncRepository;
  SyncManager get syncManager =>
      _syncManager; // Se asegura que SyncManager esté disponible
  FirebaseService get firebaseService => _firebaseService;
  DatabaseHelper get databaseHelper => _databaseHelper;

  // Repository Getters
  HabitRepository get habitRepository => _habitRepository;
  StatisticsRepository get statisticsRepository => _statisticsRepository;
  AIAssistantRepository get aiAssistantRepository => _aiAssistantRepository;
  SettingsRepository get settingsRepository => _settingsRepository;

  Future<void> dispose() async {
    try {
      _aiRepository.dispose();
      await _syncManager.dispose();
      await _databaseHelper.close();
    } catch (e) {
      rethrow;
    }
  }
}
