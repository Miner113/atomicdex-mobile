part of 'bloc_manager_widget.dart';

class BlocManager {
  static final BlocManager _blocManager = BlocManager._internal();

  factory BlocManager() {
    return _blocManager;
  }

  // Singleton initialization
  BlocManager._internal();

  Future<void> init() async {
    if (_isInitialized) throw Exception('BlocManager is already initialized');

    // Initialize persistance
    await _initPersistance();

    await _initRepositories();

    // Set initialized
    _isInitialized = true;
  }

  //===========================  Repositories  ===========================
  // TODO: Add 'late' and 'final' after null safety
  SharedPreferences? _prefs;

  late final AuthenticationRepository? _authenticationRepository;

  //=====================================================================

  // Is initialized
  bool _isInitialized = false;

  // Initialize HydratedBloc
  Future<void> _initPersistance() async {
    final storage = await HydratedStorage.build(
      storageDirectory: await applicationDocumentsDirectory,
    );

    HydratedBloc.storage = storage;
  }

  Future<void> _initRepositories() async {
    try {
      // Initialize sync constructor repositories

      // Initialize async repositories which cannot be initialized in parallel
      _prefs = await SharedPreferences.getInstance();

      // Initialize async repositories which can be initialized in parallel
      final futures = <Future<void>>[
        Future(() async {
          _authenticationRepository = AuthenticationRepository();

          await _authenticationRepository!.init();
        }),
      ];

      await Future.wait(futures);

      // Initialize repositories which depend on other repositories
    } catch (e) {
      print('Fatal error: Error initializing repositories. App should exit.');
      print(e);
      rethrow;
    }
  }

  final _blocMap = <String, Bloc>{};

  void registerBloc(String key, Bloc bloc) {
    _blocMap[key] = bloc;
  }

  void disposeBloc(String key) {
    _blocMap[key]?.close();
    _blocMap.remove(key);
  }

  void disposeAll() {
    _blocMap.forEach((key, bloc) {
      // Dispose bloc
      bloc.close();

      // Remove bloc from map
      _blocMap.remove(key);
    });

    _blocMap.clear();
  }
}
