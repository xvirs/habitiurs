import 'package:firebase_core/firebase_core.dart';

// Core
import '../database/database_helper.dart';
import '../ai/repositories/ai_repository.dart';
import '../auth/services/auth_service.dart';
import '../auth/interfaces/i_auth_service.dart';
import '../sync/services/firebase_service.dart';
import '../sync/services/sync_manager.dart';
import '../sync/repositories/sync_repository.dart';

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

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic> _singletons = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    print('🚀 [DI] Initializing services...');
    
    try {
      await _initializeFirebase();
      await _initializeCoreServices();
      _initializeRepositories();
      _initializeUseCases();
      _isInitialized = true;
      print('✅ [DI] Services initialized successfully');
    } catch (e) {
      print('❌ [DI] Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  T get<T>() {
    if (!_isInitialized) {
      throw StateError('InjectionContainer must be initialized before use');
    }

    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }

    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    throw Exception('Service of type $T not registered');
  }

  bool isRegistered<T>() => _services.containsKey(T) || _singletons.containsKey(T);

  void _registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  void _registerFactory<T>(T Function() factory) {
    _services[T] = factory;
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      print('✅ [Firebase] Initialized');
    } catch (e) {
      print('⚠️ [Firebase] Failed to initialize: $e');
      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    // Database
    final databaseHelper = SqliteDatabaseHelper();
    await databaseHelper.database;
    _registerSingleton<DatabaseHelper>(databaseHelper);
    print('✅ [Database] SQLite initialized');

    // DataSources
    final habitLocalDataSource = HabitLocalDataSourceImpl(databaseHelper);
    final statisticsLocalDatasource = StatisticsLocalDatasourceImpl(databaseHelper: databaseHelper);
    final offlineContentDatasource = OfflineContentDatasourceImpl();
    
    _registerSingleton<HabitLocalDataSource>(habitLocalDataSource);
    _registerSingleton<StatisticsLocalDatasource>(statisticsLocalDatasource);
    _registerSingleton<OfflineContentDatasource>(offlineContentDatasource);
    print('✅ [DataSources] Initialized');

    // AI Repository
    final aiRepository = AIRepository();
    _registerSingleton<AIRepository>(aiRepository);
    print('✅ [AI] Repository initialized');

    // Auth Service
    final authService = AuthService();
    _registerSingleton<IAuthService>(authService);
    _registerSingleton<AuthService>(authService);
    print('✅ [Auth] Service initialized');

    // Firebase Service
    final firebaseService = FirebaseService();
    _registerSingleton<FirebaseService>(firebaseService);
    print('✅ [Firebase] Service initialized');

    // Sync Manager
    final syncManager = SyncManager(
      firebaseService: firebaseService,
      authService: authService,
      habitDataSource: habitLocalDataSource,
      statisticsDataSource: statisticsLocalDatasource,
    );
    _registerSingleton<SyncManager>(syncManager);
    print('✅ [Sync] Manager initialized');

    // Sync Repository
    final syncRepository = SyncRepositoryImpl(
      syncManager: syncManager,
      firebaseService: firebaseService,
      authService: authService,
    );
    _registerSingleton<SyncRepository>(syncRepository);
    print('✅ [Sync] Repository initialized');
  }

  void _initializeRepositories() {
    final habitRepository = HabitRepositoryImpl(
      get<HabitLocalDataSource>(),
      get<SyncRepository>(),
    );
    _registerSingleton<HabitRepository>(habitRepository);

    final statisticsRepository = StatisticsRepositoryImpl(
      localDatasource: get<StatisticsLocalDatasource>(),
    );
    _registerSingleton<StatisticsRepository>(statisticsRepository);

    final aiAssistantRepository = AIAssistantRepositoryImpl(
      offlineContentDatasource: get<OfflineContentDatasource>(),
      aiRepository: get<AIRepository>(),
      habitRepository: habitRepository,
    );
    _registerSingleton<AIAssistantRepository>(aiAssistantRepository);
    print('✅ [Repositories] Initialized');
  }

  void _initializeUseCases() {
    _initializeAuthUseCases();
    _initializeHabitsUseCases();
    _initializeStatisticsUseCases();
    _initializeAIAssistantUseCases();
    print('✅ [UseCases] Initialized');
  }

  void _initializeAuthUseCases() {
    final authService = get<IAuthService>();
    
    _registerSingleton<CheckAuthStatus>(CheckAuthStatus(authService));
    _registerSingleton<CreateGuestSession>(CreateGuestSession(authService));
    _registerSingleton<LoginWithGoogle>(LoginWithGoogle(authService));
    _registerSingleton<LogoutUser>(LogoutUser(authService));
  }

  void _initializeHabitsUseCases() {
    final habitRepository = get<HabitRepository>();
    final authService = get<IAuthService>();
    
    _registerSingleton<GetAllHabits>(GetAllHabits(habitRepository));
    _registerSingleton<CreateHabit>(CreateHabit(habitRepository));
    _registerSingleton<GetWeekEntries>(GetWeekEntries(habitRepository));
    _registerSingleton<ToggleHabitEntry>(ToggleHabitEntry(habitRepository));
    _registerSingleton<DeleteHabit>(DeleteHabit(habitRepository, authService));
  }

  void _initializeStatisticsUseCases() {
    final statisticsRepository = get<StatisticsRepository>();
    
    _registerSingleton<GetCurrentMonthStatistics>(GetCurrentMonthStatistics(statisticsRepository));
    _registerSingleton<GetCurrentYearStatistics>(GetCurrentYearStatistics(statisticsRepository));
    _registerSingleton<GetHistoricalData>(GetHistoricalData(statisticsRepository));
  }

  void _initializeAIAssistantUseCases() {
    final aiAssistantRepository = get<AIAssistantRepository>();
    
    _registerSingleton<GetEducationalContent>(GetEducationalContent(aiAssistantRepository));
    _registerSingleton<GetAppGuides>(GetAppGuides(aiAssistantRepository));
    _registerSingleton<GetAIRecommendation>(GetAIRecommendation(aiAssistantRepository));
  }

  // BLoC Factories
  AuthBloc get authBloc => AuthBloc(
    checkAuthStatus: get<CheckAuthStatus>(),
    createGuestSession: get<CreateGuestSession>(),
    loginWithGoogle: get<LoginWithGoogle>(),
    logoutUser: get<LogoutUser>(),
  );

  HabitBloc get habitBloc => HabitBloc(
    getAllHabits: get<GetAllHabits>(),
    createHabit: get<CreateHabit>(),
    getWeekEntries: get<GetWeekEntries>(),
    toggleHabitEntry: get<ToggleHabitEntry>(),
    deleteHabit: get<DeleteHabit>(),
  );

  StatisticsBloc get statisticsBloc => StatisticsBloc(
    getCurrentMonthStatistics: get<GetCurrentMonthStatistics>(),
    getCurrentYearStatistics: get<GetCurrentYearStatistics>(),
    getHistoricalData: get<GetHistoricalData>(),
  );

  AIAssistantBloc get aiAssistantBloc => AIAssistantBloc(
    getEducationalContent: get<GetEducationalContent>(),
    getAppGuides: get<GetAppGuides>(),
    getAIRecommendation: get<GetAIRecommendation>(),
  );

  HabitEvaluationCubit get habitEvaluationCubit => HabitEvaluationCubit(
    aiRepository: get<AIRepository>(),
  );

  Future<void> dispose() async {
    print('🧹 [DI] Cleaning up resources...');
    try {
      final aiRepository = get<AIRepository>();
      final syncManager = get<SyncManager>();
      final databaseHelper = get<DatabaseHelper>();
      
      await aiRepository.dispose();
      await syncManager.dispose();
      await databaseHelper.close();
      
      _services.clear();
      _singletons.clear();
      _isInitialized = false;
      print('✅ [DI] Resources cleaned up');
    } catch (e) {
      print('⚠️ [DI] Error during cleanup: $e');
      rethrow;
    }
  }
}