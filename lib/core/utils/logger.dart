// O QUE É ISSO?
// ------------
// Logger centralizado. Em vez de usar print() no código
// (que aparece em produção e polui o console), usamos
// níveis de log:
//
//   AppLogger.d('mensagem')  → debug   (só em desenvolvimento)
//   AppLogger.i('mensagem')  → info    (eventos importantes)
//   AppLogger.w('mensagem')  → warning (situações suspeitas)
//   AppLogger.e('mensagem')  → error   (erros com stacktrace)
//
// Em produção (release), logs de debug são suprimidos automaticamente.

import 'package:logger/web.dart';

class AppLogger {
  static final Logger _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat:  DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: const bool.fromEnvironment('dart.vm.product')
        ? Level.warning
        : Level.debug,
  );

static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.d(message, error: error, stackTrace:  stackTrace);
}

static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.i(message, error: error, stackTrace:  stackTrace);
}

static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.w(message, error: error, stackTrace: stackTrace);
}

static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  _logger.e(message, error: error, stackTrace: stackTrace);
}

}
