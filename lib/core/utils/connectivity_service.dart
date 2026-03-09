// O QUE É ISSO?
// ------------
// Serviço que monitora o estado da conexão de rede em tempo real.
// Expõe um Stream que emite true/false conforme a conexão muda.
//
// CONCEITOS DART USADOS:
// ----------------------
// StreamController → cria um "cano" de dados que emite eventos
//   - .stream   → lado de leitura (quem escuta)
//   - .add()    → lado de escrita (quem produz dados)
//
// StreamSubscription → representa uma "assinatura" no stream,
//   guarda a referência para cancelar depois (evitar memory leak)
//
// async/await → torna operações assíncronas legíveis como síncronas

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mirae_coletor/core/utils/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StreamSubscription? _subscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> initialize() async {
    await _checkCurrentStatus();

    _subscription = _connectivity.onConnectivityChanged.listen(
      (dynamic result) {
        final list = _toList(result);
        _handleConnectivityChange(list);
      },
      onError: (error) {
        AppLogger.e('ConnectivityService: erro no stream', error);
      },
    );

    AppLogger.i('ConnectivityService inicializado. Conectado: $_isConnected');
  }

  Future<bool> _checkCurrentStatus() async {
    final dynamic result = await _connectivity.checkConnectivity();
    final list = _toList(result);
    _isConnected = _hasConnection(list);
    _connectionController.add(_isConnected);
    return _isConnected;
  }

  Future<bool> checkConnection() async {
    return await _checkCurrentStatus();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasConnection(results);

    if (wasConnected != _isConnected) {
      AppLogger.i(
        'Conectividade: ${_isConnected ? "ONLINE ✓" : "OFFLINE ✗"} '
        '(${_connectionTypeLabel(results)})',
      );
      _connectionController.add(_isConnected);
    }
  }

  List<ConnectivityResult> _toList(dynamic result) {
    if (result is List<ConnectivityResult>) return result;
    if (result is ConnectivityResult) return [result];
    return [ConnectivityResult.none];
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  String _connectionTypeLabel(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.mobile)) return 'Dados móveis';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Nenhuma';
  }

  Future<bool> isOnWifi() async {
    final dynamic result = await _connectivity.checkConnectivity();
    final list = _toList(result);
    return list.contains(ConnectivityResult.wifi);
  }

  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
    AppLogger.d('ConnectivityService: disposed');
  }
}



