//
// O QUE É ISSO?
// ------------
// Wrapper do Dio configurado com todos os interceptors,
// timeouts e tratamento de erros centralizado.
//
// Por que wrappear o Dio?
// → Centraliza a configuração em um lugar
// → Facilita trocar a biblioteca HTTP no futuro
// → Converte exceções do Dio em Failures do nosso domínio
//
// CONCEITO: Either<Failure, T>
// ------------------------------------------------
// Toda chamada de API retorna Either<Failure, T>:
//   Left(ServerFailure(...))  → algo deu errado
//   Right(dadosRetornados)    → sucesso
//
// O chamador usa:
//   final result = await apiClient.get('/endpoint');
//   result.fold(
//     (failure) => trataErro(failure),
//     (data)    => usaDados(data),
//   );

import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mirae_coletor/core/utils/logger.dart';
import '../errors/failures.dart';
//import 'interceptors/auth_interceptor.dart';
//import 'interceptors/retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _serverUrlKey = 'server_url';

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': '1.0.0',
          'X-Platform': 'mobile',
        },
      ),
    );

    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => AppLogger.d(obj.toString()),
      ),
    ]);
  }


  ApiClient({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage {
    _initDio();
  }

  Future<void> updateBaseUrl(String serverUrl) async {
    _dio.options.baseUrl = serverUrl;
    await _secureStorage.write(key: _serverUrlKey, value: serverUrl);
    AppLogger.i('ApiClient: baseUrl atualizada para $serverUrl');
  }

  Future<void> restoreBaseUrl() async {
    final savedUrl = await _secureStorage.read(key: _serverUrlKey);
    if (savedUrl != null) {
      _dio.options.baseUrl = savedUrl;
      AppLogger.i('ApiClient: baseUrl restaurada: $savedUrl');
    }
  }

  String _extractErrorMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Erro no servidor';
      }
    } catch (_) {}
    return 'Erro no servidor (${response?.statusCode})';
  }

  Failure _handleDioException(DioException e) {
    AppLogger.i('ApiClient: DioException ${e.type}', e.message);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response);

        if (statusCode == 401) {
          return AuthFailure(message);
        }
        if (statusCode == 404) {
          return NotFoundFailure(message);
        }
        return ServerFailure(message, statusCode: statusCode);

      default:
        return UnexpectedFailure(e.message ?? 'Erro desconhecido');
    }
  }

  Future<Either<Failure, dynamic>> _execute(
    Future<Response> Function() call,
  ) async {
    try {
      final response = await call();
      AppLogger.d('ApiClient: sucesso ${response.statusCode}');
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e, stack) {
      AppLogger.i('ApiClient: erro inesperado', e, stack);
      return Left(UnexpectedFailure(e.toString()));
    }
  }


  Future<Either<Failure, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    return _execute(
      () => _dio.get(path, queryParameters: queryParams),
    );
  }

  Future<Either<Failure, dynamic>> post(
    String path, {
    dynamic data,
  }) async {
    return _execute(
      () => _dio.post(path, data: data),
    );
  }

  Future<Either<Failure, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    return _execute(
      () => _dio.put(path, data: data),
    );
  }

  Future<Either<Failure, dynamic>> delete(String path) async {
    return _execute(
      () => _dio.delete(path),
    );
  }


}
