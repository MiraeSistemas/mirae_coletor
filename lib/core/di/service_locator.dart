// O QUE É ISSO?
// ------------
// Injeção de Dependência com get_it.
//
// PROBLEMA QUE RESOLVE:
// Sem DI, para usar o SyncManager precisaria criar manualmente:
//   final db = DatabaseHelper.instance;
//   final queue = SyncQueue(db: db);
//   final connectivity = ConnectivityService();
//   final storage = FlutterSecureStorage();
//   final apiClient = ApiClient(secureStorage: storage);
//   final syncManager = SyncManager(queue: queue, ...);
//
// Com get_it, registra uma vez e pega em qualquer lugar:
//   sl<SyncManager>().syncAll()
//
// TIPOS DE REGISTRO:
// registerSingleton    → cria UMA instância imediatamente e reutiliza
// registerLazySingleton → cria UMA instância na PRIMEIRA vez que for pedida
// registerFactory      → cria uma NOVA instância toda vez que for pedida
//
// CONVENÇÃO:
// 'sl' = service locator (nome curto para uso frequente)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:mirae_coletor/core/utils/logger.dart';
import '../database/database_helper.dart';
import '../network/api_client.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_queue.dart';
import '../utils/connectivity_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  AppLogger.i('ServiceLocator: inicializando...');

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerLazySingleton<DatabaseHelper>(
    () => DatabaseHelper.instance,
  );

  final connectivityService = ConnectivityService();
  await connectivityService.initialize(); // inicia o monitoramento
  sl.registerSingleton<ConnectivityService>(connectivityService);

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(secureStorage: sl<FlutterSecureStorage>()),
  );


  sl.registerLazySingleton<SyncQueue>(
    () => SyncQueue(db: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      syncQueue: sl<SyncQueue>(),
      apiClient: sl<ApiClient>(),
      connectivity: sl<ConnectivityService>(),
      db: sl<DatabaseHelper>(),
    ),
  );

  AppLogger.i('ServiceLocator: pronto ✓');
}
