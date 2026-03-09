import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mirae_coletor/core/utils/logger.dart';
import 'core/di/service_locator.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_routes.dart';
import 'package:mirae_coletor/core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força orientação retrato — padrão para apps de campo
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa formatação de datas em pt_BR
  await initializeDateFormatting('pt_BR', null);

  AppLogger.i('App: inicializando...');
  await setupServiceLocator();
  await sl<ApiClient>().restoreBaseUrl();
  AppLogger.i('App: pronto ✓');

  runApp(const MiraeApp());
}

class MiraeApp extends StatelessWidget {
  const MiraeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirae Sistemas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
