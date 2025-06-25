// lib/core/di/injection_container.dart - MODIFICADO (Añadido getter para AuthBloc)

import 'package:firebase_core/firebase_core.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_ai_recommendation.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_app_guides.dart';

// Database
import '../database/database_helper.dart';

// AI Core
import '../ai/repositories/ai_repository.dart';
// Auth Core
import '../auth/services/auth_service.dart';
import '../auth/interfaces/i_auth_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart'; // ✅ NUEVO: Importar AuthBloc
import '../../features/auth/domain/usecases/check_auth_status.dart'; // ✅ NUEVO: Importar CheckAuthStatus
import '../../features/auth/domain/usecases/create_guest_session.dart'; // ✅ NUEVO: Importar CreateGuestSession
import '../../features/auth/domain/usecases/login_with_google.dart'; // ✅ NUEVO: Importar LoginWithGoogle
import '../../features/auth/domain/usecases/logout_user.dart'; // ✅ NUEVO: Importar LogoutUser


// Sync Core - ACTUALIZADO: Agregar SyncRepository
import '../sync/services/firebase_service.dart';
import '../sync/services/sync_manager.dart';
import '../sync/repositories/sync_repository.dart';
// Features - Habits
import '../../features/habits/data/datasources/habit_local_datasource.dart';
import '../../features/habits/data/repositories/habit_repository_impl.dart';
import '../../features/habits/domain/repositories/habit_repository.dart';
import '../../features/habits/domain/usecases/create_habit.dart';
import '../../features/habits/domain/usecases/delete_habit.dart';
import '../../features/habits/domain/usecases/get_all_habits.dart';
import '../../features/habits/domain/usecases/get_week_entries.dart';
import '../../features/habits/domain/usecases/toggle_habit_entry.dart';
import '../../features/habits/presentation/bloc/habit_bloc.dart';

// NUEVO: Importar HabitEvaluationCubit
import '../../features/habits/presentation/bloc/habit_evaluation_cubit.dart'; 

// Features - Statistics
import '../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_current_month_statistics.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';
// Features - AI Assistant
import '../../features/ai_assistant/data/datasources/offline_content_datasource.dart';
import '../../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import '../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../../features/ai_assistant/domain/usecases/get_educational_content.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

// CORE SERVICES
  late final DatabaseHelper _databaseHelper;
  late final AIRepository _aiRepository;
  late final IAuthService _authService;
  late final FirebaseService _firebaseService;
  late final SyncManager _syncManager;
  late final SyncRepository _syncRepository; 

  // DATASOURCES
  late final HabitLocalDataSource _habitLocalDataSource;
  late final StatisticsLocalDatasource _statisticsLocalDatasource;
  late final OfflineContentDatasource _offlineContentDatasource;

  // REPOSITORIES
  late final HabitRepository _habitRepository;
  late final StatisticsRepository _statisticsRepository;
  late final AIAssistantRepository _aiAssistantRepository;

  // USE CASES - Auth (NUEVOS)
  late final CheckAuthStatus _checkAuthStatus;
  late final CreateGuestSession _createGuestSession;
  late final LoginWithGoogle _loginWithGoogle;
  late final LogoutUser _logoutUser;


  // USE CASES - Habits
  late final GetAllHabits _getAllHabits;
  late final CreateHabit _createHabit;
  late final GetWeekEntries _getWeekEntries;
  late final ToggleHabitEntry _toggleHabitEntry;
  late final DeleteHabit _deleteHabit; 
// USE CASES - Statistics
  late final GetCurrentMonthStatistics _getCurrentMonthStatistics;
  late final GetCurrentYearStatistics _getCurrentYearStatistics;
  late final GetHistoricalData _getHistoricalData;
// USE CASES - AI Assistant
  late final GetEducationalContent _getEducationalContent;
  late final GetAppGuides _getAppGuides;
  late final GetAIRecommendation _getAIRecommendation;
// Initialization flag
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    print('🚀 [DI] Inicializando servicios...');

    try {
      // 1. Inicializar Firebase
      await _initializeFirebase();
      // 2. Inicializar Core Services
      await _initializeCoreServices();
      // 3. Inicializar Repositories (datasources ya están listos)
      _initializeRepositories();
      // 4. Inicializar Use Cases
      _initializeUseCases();

      _isInitialized = true;
      print('✅ [DI] Servicios inicializados correctamente');
    } catch (e) {
      print('❌ [DI] Error en inicialización: $e');
      _isInitialized = false;
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      print('✅ [Firebase] Inicializado');
    } catch (e) {
      print('⚠️ [Firebase] Error inicializando: $e');
      // Continuar sin Firebase (modo offline)
    }
  }

  // ORDEN DE INICIALIZACIÓN ACTUALIZADO
  Future<void> _initializeCoreServices() async {
    // Database
    _databaseHelper = SqliteDatabaseHelper();
    await _databaseHelper.database; // Asegurar inicialización
    print('✅ [Database] SQLite inicializado');
    // CRÍTICO: Inicializar datasources ANTES de SyncManager
    _initializeDataSources();
    // AI Repository (incluye Gemini + Fallback)
    _aiRepository = AIRepository();
    print('✅ [AI] Repository inicializado');
    // Auth Service
    _authService = AuthService();
    print('✅ [Auth] Service inicializado');
    // Firebase Service
    _firebaseService = FirebaseService();
    print('✅ [Firebase] Service inicializado');
    // Sync Manager - Con datasources
    _syncManager = SyncManager(
      firebaseService: _firebaseService,
      authService: _authService,
      habitDataSource: _habitLocalDataSource,
      statisticsDataSource: _statisticsLocalDatasource,
    );
    print('✅ [Sync] Manager inicializado');

    // Sync Repository
    _syncRepository = SyncRepositoryImpl(
      syncManager: _syncManager,
      firebaseService: _firebaseService,
      authService: _authService,
    );
    print('✅ [Sync] Repository inicializado');
  }

  void _initializeDataSources() {
    _habitLocalDataSource = HabitLocalDataSourceImpl(_databaseHelper);
    _statisticsLocalDatasource = StatisticsLocalDatasourceImpl(databaseHelper: _databaseHelper);
    _offlineContentDatasource = OfflineContentDatasourceImpl();
    print('✅ [DataSources] Inicializados');
  }

  void _initializeRepositories() {
    _habitRepository = HabitRepositoryImpl(_habitLocalDataSource, _syncRepository, _authService); 
    _statisticsRepository = StatisticsRepositoryImpl(localDatasource: _statisticsLocalDatasource);
    
    _aiAssistantRepository = AIAssistantRepositoryImpl(
      offlineContentDatasource: _offlineContentDatasource,
      aiRepository: _aiRepository,
      habitRepository: _habitRepository,
    );
    print('✅ [Repositories] Inicializados');
  }

  void _initializeUseCases() {
    // Auth Use Cases (NUEVOS)
    _checkAuthStatus = CheckAuthStatus(_authService);
    _createGuestSession = CreateGuestSession(_authService);
    _loginWithGoogle = LoginWithGoogle(_authService);
    _logoutUser = LogoutUser(_authService);

    // Habits Use Cases
    _getAllHabits = GetAllHabits(_habitRepository);
    _createHabit = CreateHabit(_habitRepository);
    _getWeekEntries = GetWeekEntries(_habitRepository);
    _toggleHabitEntry = ToggleHabitEntry(_habitRepository);
    _deleteHabit = DeleteHabit(_habitRepository, _authService);

    // Statistics Use Cases
    _getCurrentMonthStatistics = GetCurrentMonthStatistics(_statisticsRepository);
    _getCurrentYearStatistics = GetCurrentYearStatistics(_statisticsRepository);
    _getHistoricalData = GetHistoricalData(_statisticsRepository);

    // AI Assistant Use Cases
    _getEducationalContent = GetEducationalContent(_aiAssistantRepository);
    _getAppGuides = GetAppGuides(_aiAssistantRepository);
    _getAIRecommendation = GetAIRecommendation(_aiAssistantRepository);

    print('✅ [UseCases] Inicializados');
  }

  // GETTERS PARA BLOCS (Ajustados para no disparar eventos de carga aquí)
  // ✅ NUEVO GETTER para AuthBloc
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

  // NUEVO GETTER: Para el HabitEvaluationCubit
  HabitEvaluationCubit get habitEvaluationCubit => HabitEvaluationCubit(
    aiRepository: _aiRepository,
  );

// GETTERS PARA SERVICIOS CORE
  AIRepository get aiRepository => _aiRepository;
  IAuthService get authService => _authService;
  SyncRepository get syncRepository => _syncRepository;
  SyncManager get syncManager => _syncManager;
  FirebaseService get firebaseService => _firebaseService;
  DatabaseHelper get databaseHelper => _databaseHelper;
// GETTERS PARA REPOSITORIES
  HabitRepository get habitRepository => _habitRepository;
  StatisticsRepository get statisticsRepository => _statisticsRepository;
  AIAssistantRepository get aiAssistantRepository => _aiAssistantRepository;
// CLEANUP
  Future<void> dispose() async {
    print('🧹 [DI] Limpiando recursos...');
    try {
      _aiRepository.dispose();
      await _syncManager.dispose();
      await _databaseHelper.close();
      print('✅ [DI] Recursos liberados');
    } catch (e) {
      print('⚠️ [DI] Error limpiando recursos: $e');
    }
  }
}