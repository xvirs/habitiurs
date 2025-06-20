// lib/core/di/injection_container.dart - ACTUALIZADO PARA AI ASSISTANT REFACTORIZADO
import 'package:firebase_core/firebase_core.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_ai_recommendation.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_app_guides.dart';

// Database
import '../database/database_helper.dart';

// AI Core
import '../ai/repositories/ai_repository.dart';

// Auth Core
import '../auth/services/auth_service.dart';

// Sync Core
import '../sync/services/firebase_service.dart';
import '../sync/services/sync_manager.dart';

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

// Features - Statistics
import '../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_current_month_statistics.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';

// Features - AI Assistant (REFACTORIZADO)
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
  late final AuthService _authService;
  late final FirebaseService _firebaseService;
  late final SyncManager _syncManager;

  // DATASOURCES
  late final HabitLocalDataSource _habitLocalDataSource;
  late final StatisticsLocalDatasource _statisticsLocalDatasource;
  late final OfflineContentDatasource _offlineContentDatasource; // ✅ Solo contenido offline

  // REPOSITORIES
  late final HabitRepository _habitRepository;
  late final StatisticsRepository _statisticsRepository;
  late final AIAssistantRepository _aiAssistantRepository;

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

  // USE CASES - AI Assistant (REFACTORIZADO)
  late final GetEducationalContent _getEducationalContent;
  late final GetAppGuides _getAppGuides;
  late final GetAIRecommendation _getAIRecommendation; // ✅ Simplificado

  // Initialization flag
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    print('🚀 [DI] Inicializando servicios...');

    // 1. Inicializar Firebase
    await _initializeFirebase();

    // 2. Inicializar Core Services
    await _initializeCoreServices();

    // 3. Inicializar DataSources
    _initializeDataSources();

    // 4. Inicializar Repositories
    _initializeRepositories();

    // 5. Inicializar Use Cases
    _initializeUseCases();

    _isInitialized = true;
    print('✅ [DI] Servicios inicializados correctamente');
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('✅ [Firebase] Inicializado');
    } catch (e) {
      print('⚠️ [Firebase] Error inicializando: $e');
      // Continuar sin Firebase (modo offline)
    }
  }

  Future<void> _initializeCoreServices() async {
    // Database
    _databaseHelper = SqliteDatabaseHelper();
    await _databaseHelper.database; // Asegurar inicialización
    print('✅ [Database] SQLite inicializado');

    // AI Repository (incluye Gemini + Fallback)
    _aiRepository = AIRepository();
    print('✅ [AI] Repository inicializado');

    // Auth Service
    _authService = AuthService();
    print('✅ [Auth] Service inicializado');

    // Firebase Service
    _firebaseService = FirebaseService();
    print('✅ [Firebase] Service inicializado');

    // Sync Manager
    _syncManager = SyncManager(
      firebaseService: _firebaseService,
      authService: _authService,
    );
    print('✅ [Sync] Manager inicializado');
  }

  void _initializeDataSources() {
    _habitLocalDataSource = HabitLocalDataSourceImpl(_databaseHelper);
    _statisticsLocalDatasource = StatisticsLocalDatasourceImpl(databaseHelper: _databaseHelper);
    
    // ✅ AI Assistant - Solo contenido educativo y guías offline
    _offlineContentDatasource = OfflineContentDatasourceImpl();
    
    print('✅ [DataSources] Inicializados');
  }

  void _initializeRepositories() {
    _habitRepository = HabitRepositoryImpl(_habitLocalDataSource);
    _statisticsRepository = StatisticsRepositoryImpl(localDatasource: _statisticsLocalDatasource);
    
    // ✅ AI Assistant Repository - REFACTORIZADO para usar AI centralizado
    _aiAssistantRepository = AIAssistantRepositoryImpl(
      offlineContentDatasource: _offlineContentDatasource,
      aiRepository: _aiRepository, // ✅ Usar AIRepository centralizado del core
      habitRepository: _habitRepository, // Para generar contexto de usuario
    );
    
    print('✅ [Repositories] Inicializados');
  }

  void _initializeUseCases() {
    // Habits
    _getAllHabits = GetAllHabits(_habitRepository);
    _createHabit = CreateHabit(_habitRepository);
    _getWeekEntries = GetWeekEntries(_habitRepository);
    _toggleHabitEntry = ToggleHabitEntry(_habitRepository);
    _deleteHabit = DeleteHabit(_habitRepository);

    // Statistics
    _getCurrentMonthStatistics = GetCurrentMonthStatistics(_statisticsRepository);
    _getCurrentYearStatistics = GetCurrentYearStatistics(_statisticsRepository);
    _getHistoricalData = GetHistoricalData(_statisticsRepository);

    // ✅ AI Assistant - Use Cases simplificados
    _getEducationalContent = GetEducationalContent(_aiAssistantRepository);
    _getAppGuides = GetAppGuides(_aiAssistantRepository);
    _getAIRecommendation = GetAIRecommendation(_aiAssistantRepository); // ✅ Delega al core

    print('✅ [UseCases] Inicializados');
  }

  // GETTERS PARA BLOCS

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

  // ✅ AI Assistant BLoC - REFACTORIZADO
  AIAssistantBloc get aiAssistantBloc => AIAssistantBloc(
    getEducationalContent: _getEducationalContent,
    getAppGuides: _getAppGuides,
    getAIRecommendation: _getAIRecommendation, // ✅ Use case simplificado
  );

  // GETTERS PARA SERVICIOS CORE

  /// AI Repository centralizado - Acceso directo para todas las features
  AIRepository get aiRepository => _aiRepository;

  /// Auth Service - Para login/logout/estado de usuario
  AuthService get authService => _authService;

  /// Sync Manager - Para sincronización manual o automática
  SyncManager get syncManager => _syncManager;

  /// Firebase Service - Para operaciones directas de Firebase
  FirebaseService get firebaseService => _firebaseService;

  /// Database Helper - Para operaciones directas de SQLite
  DatabaseHelper get databaseHelper => _databaseHelper;

  // GETTERS PARA REPOSITORIES (para use cases avanzados)

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

// ============================================================================
// 🔄 CAMBIOS REALIZADOS EN ESTA ACTUALIZACIÓN:
// ============================================================================

// ✅ AGREGADOS:
// - import '../../features/ai_assistant/domain/usecases/get_app_guides.dart';
// - import '../../features/ai_assistant/domain/usecases/get_ai_recommendation.dart';
// - late final GetAppGuides _getAppGuides;
// - late final GetAIRecommendation _getAIRecommendation;

// ✅ COMENTARIOS AÑADIDOS:
// - Comentarios explicativos sobre la refactorización
// - Marcadores ✅ para indicar cambios
// - Documentación de que AIAssistantRepository ahora usa AI centralizado

// 🗑️ SIN CAMBIOS INNECESARIOS:
// - No se agregaron imports de archivos eliminados
// - No se modificó la estructura existente
// - Solo se añadieron los use cases faltantes

// ✅ LÓGICA ACTUALIZADA:
// - AIAssistantRepository ahora usa _aiRepository del core
// - GetAIRecommendation simplificado (delega al core)
// - Comentarios que explican el nuevo flujo