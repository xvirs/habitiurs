// lib/core/di/injection_container.dart
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

  // Core Services
  late final DatabaseHelper _databaseHelper;
  late final AIRepository _aiRepository;
  late final IAuthService _authService;
  late final FirebaseService _firebaseService;
  late final SyncManager _syncManager;
  late final SyncRepository _syncRepository;

  // DataSources
  late final HabitLocalDataSource _habitLocalDataSource;
  late final StatisticsLocalDatasource _statisticsLocalDatasource;
  late final OfflineContentDatasource _offlineContentDatasource;

  // Repositories
  late final HabitRepository _habitRepository;
  late final StatisticsRepository _statisticsRepository;
  late final AIAssistantRepository _aiAssistantRepository;

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
  late final DeleteHabit _deleteHabit;

  // Statistics Use Cases
  late final GetCurrentMonthStatistics _getCurrentMonthStatistics;
  late final GetCurrentYearStatistics _getCurrentYearStatistics;
  late final GetHistoricalData _getHistoricalData;

  // AI Assistant Use Cases
  late final GetEducationalContent _getEducationalContent;
  late final GetAppGuides _getAppGuides;
  late final GetAIRecommendation _getAIRecommendation;

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

    _initializeDataSources();

    _aiRepository = AIRepository();
    _authService = AuthService();
    _firebaseService = FirebaseService();

    _syncManager = SyncManager(
      firebaseService: _firebaseService,
      authService: _authService,
      habitDataSource: _habitLocalDataSource,
      statisticsDataSource: _statisticsLocalDatasource,
    );

    _syncRepository = SyncRepositoryImpl(
      syncManager: _syncManager,
      firebaseService: _firebaseService,
      authService: _authService,
    );
  }

  void _initializeDataSources() {
    _habitLocalDataSource = HabitLocalDataSourceImpl(_databaseHelper);
    _statisticsLocalDatasource = StatisticsLocalDatasourceImpl(databaseHelper: _databaseHelper);
    _offlineContentDatasource = OfflineContentDatasourceImpl();
  }

  void _initializeRepositories() {
    _habitRepository = HabitRepositoryImpl(
      _habitLocalDataSource, 
      _syncRepository,
    );
    
    _statisticsRepository = StatisticsRepositoryImpl(
      localDatasource: _statisticsLocalDatasource,
    );

    _aiAssistantRepository = AIAssistantRepositoryImpl(
      offlineContentDatasource: _offlineContentDatasource,
      aiRepository: _aiRepository,
      habitRepository: _habitRepository,
    );
  }

  void _initializeUseCases() {
    _initializeAuthUseCases();
    _initializeHabitsUseCases();
    _initializeStatisticsUseCases();
    _initializeAIAssistantUseCases();
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
    _getWeekEntries = GetWeekEntries(_habitRepository);
    _toggleHabitEntry = ToggleHabitEntry(_habitRepository);
    _deleteHabit = DeleteHabit(_habitRepository, _authService);
  }

  void _initializeStatisticsUseCases() {
    _getCurrentMonthStatistics = GetCurrentMonthStatistics(_statisticsRepository);
    _getCurrentYearStatistics = GetCurrentYearStatistics(_statisticsRepository);
    _getHistoricalData = GetHistoricalData(_statisticsRepository);
  }

  void _initializeAIAssistantUseCases() {
    _getEducationalContent = GetEducationalContent(_aiAssistantRepository);
    _getAppGuides = GetAppGuides(_aiAssistantRepository);
    _getAIRecommendation = GetAIRecommendation(_aiAssistantRepository);
  }

  // BLoC Getters
  AuthBloc get authBloc => AuthBloc(
    checkAuthStatus: _checkAuthStatus,
    createGuestSession: _createGuestSession,
    loginWithGoogle: _loginWithGoogle,
    logoutUser: _logoutUser,
  );

  HabitBloc get habitBloc => HabitBloc(
    getAllHabits: _getAllHabits,
    createHabit: _createHabit,
    getWeekEntries: _getWeekEntries,
    toggleHabitEntry: _toggleHabitEntry,
    deleteHabit: _deleteHabit,
  );

  StatisticsBloc get statisticsBloc => StatisticsBloc(
    getCurrentMonthStatistics: _getCurrentMonthStatistics,
    getCurrentYearStatistics: _getCurrentYearStatistics,
    getHistoricalData: _getHistoricalData,
  );

  AIAssistantBloc get aiAssistantBloc => AIAssistantBloc(
    getEducationalContent: _getEducationalContent,
    getAppGuides: _getAppGuides,
    getAIRecommendation: _getAIRecommendation,
  );

  HabitEvaluationCubit get habitEvaluationCubit => HabitEvaluationCubit(
    aiRepository: _aiRepository,
  );

  // Core Service Getters
  AIRepository get aiRepository => _aiRepository;
  IAuthService get authService => _authService;
  SyncRepository get syncRepository => _syncRepository;
  SyncManager get syncManager => _syncManager;
  FirebaseService get firebaseService => _firebaseService;
  DatabaseHelper get databaseHelper => _databaseHelper;

  // Repository Getters
  HabitRepository get habitRepository => _habitRepository;
  StatisticsRepository get statisticsRepository => _statisticsRepository;
  AIAssistantRepository get aiAssistantRepository => _aiAssistantRepository;

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