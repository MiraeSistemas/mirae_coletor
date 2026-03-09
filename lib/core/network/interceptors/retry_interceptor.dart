// O QUE É ISSO?
// ------------
// Tenta repetir requisições que falharam por problemas de rede
// (timeout, conexão instável) antes de propagar o erro.
//
// Estratégia: Exponential Backoff
// Tentativa 1 → aguarda 1s → tenta de novo
// Tentativa 2 → aguarda 2s → tenta de novo
// Tentativa 3 → aguarda 4s → desiste e propaga o erro
//
// Erros que SÃO retentados:    timeout, connection error
// Erros que NÃO são retentados: 4xx (erro do cliente), 5xx (erro do servidor)

import 'package:dio/dio.dart';
import 'package:mirae_coletor/core/utils/logger.dart';

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra['retryAttempt'] ?? 0) as int;

    if (attempt >= maxRetries) {
      AppLogger.d(
        'RetryInterceptor: máximo de tentativas atingido (${attempt}x) '
        'para ${err.requestOptions.uri}',
      );
      return handler.next(err);
    }

    final delay = retryDelay * (attempt + 1);

    AppLogger.d(
      'RetryInterceptor: tentativa ${attempt + 1}/$maxRetries '
      'em ${delay.inSeconds}s para ${err.requestOptions.path}',
    );

    await Future.delayed(delay);

    final newOptions = err.requestOptions;
    newOptions.extra['retryAttempt'] = attempt + 1;

    try {
      final response = await _dio.fetch(newOptions);
      return handler.resolve(response);
    } catch (e) {
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}

