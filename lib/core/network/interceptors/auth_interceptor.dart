// O QUE É ISSO?
// ------------
// Interceptors são middlewares do Dio: código que roda
// automaticamente ANTES de cada requisição e DEPOIS de cada resposta.
//
// AuthInterceptor faz duas coisas:
// 1. Injeta o token JWT em toda requisição (Authorization header)
// 2. Detecta token expirado (401) e tenta renovar automaticamente

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mirae_coletor/core/utils/logger.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio; 

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublicRoute = _isPublicRoute(options.path);

    if (!isPublicRoute) {
      final token = await _secureStorage.read(key: _tokenKey);

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.d('AuthInterceptor: token injetado em ${options.path}');
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      AppLogger.d('AuthInterceptor: token expirado, tentando refresh...');

      final refreshed = await _tryRefreshToken();

      if (refreshed) {
        try {
          final newToken = await _secureStorage.read(key: _tokenKey);
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';

          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          AppLogger.d('AuthInterceptor: erro ao repetir requisição', e);
        }
      }

      AppLogger.d('AuthInterceptor: refresh falhou, redirecionando para login');
    }

    return handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final refreshDio = Dio();
      final serverUrl = await _secureStorage.read(key: 'server_url') ?? '';

      final response = await refreshDio.post(
        '$serverUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['token'];
        final newRefresh = response.data['refresh_token'];

        await _secureStorage.write(key: _tokenKey, value: newToken);
        if (newRefresh != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: newRefresh);
        }

        AppLogger.i('AuthInterceptor: token renovado com sucesso');
        return true;
      }
    } catch (e) {
      AppLogger.i('AuthInterceptor: erro no refresh', e);
    }
    return false;
  }

  bool _isPublicRoute(String path) {
    const publicRoutes = ['/auth/login', '/health'];
    return publicRoutes.any((route) => path.endsWith(route));
  }
}
