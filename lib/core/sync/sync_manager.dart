// O QUE É ISSO?
// ------------
// Orquestra todo o processo de sincronização:
//
// PUSH → envia registros locais pendentes para o servidor
// PULL → busca atualizações do servidor (cadastros, referências)
//
// QUANDO É CHAMADO?
// - Usuário toca "Sync Now" na tela de sincronização
// - Automaticamente ao detectar conexão WiFi (opcional)
// - Em background a cada X horas (futuro)
//
// CONCEITOS:
// Stream → fluxo de eventos que emite progressos
// StreamController → cria e controla o Stream
// yield → emite um valor em uma função geradora

import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:mirae_coletor/core/utils/logger.dart';
import '../database/database_helper.dart';
import '../errors/failures.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../utils/connectivity_service.dart';
import 'sync_queue.dart';

class SyncProgress {
  final int total;
  final int processados;
  final int enviados;
  final int falhas;
  final String mensagem;
  final bool concluido;
  final bool erro;

  const SyncProgress({
    this.total = 0,
    this.processados = 0,
    this.enviados = 0,
    this.falhas = 0,
    this.mensagem = '',
    this.concluido = false,
    this.erro = false,
  });

  double get percentual => total > 0 ? processados / total : 0.0;

  SyncProgress copyWith({
    int? total,
    int? processados,
    int? enviados,
    int? falhas,
    String? mensagem,
    bool? concluido,
    bool? erro,
  }) {
    return SyncProgress(
      total: total ?? this.total,
      processados: processados ?? this.processados,
      enviados: enviados ?? this.enviados,
      falhas: falhas ?? this.falhas,
      mensagem: mensagem ?? this.mensagem,
      concluido: concluido ?? this.concluido,
      erro: erro ?? this.erro,
    );
  }
}

class SyncManager {
  final SyncQueue _syncQueue;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;
  final DatabaseHelper _db;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncManager({
    required SyncQueue syncQueue,
    required ApiClient apiClient,
    required ConnectivityService connectivity,
    required DatabaseHelper db,
  })  : _syncQueue = syncQueue,
        _apiClient = apiClient,
        _connectivity = connectivity,
        _db = db;

  Stream<SyncProgress> syncAll() async* {
    if (_isSyncing) {
      yield const SyncProgress(
        mensagem: 'Sincronização já em andamento...',
        erro: true,
      );
      return;
    }

    if (!await _connectivity.checkConnection()) {
      yield const SyncProgress(
        mensagem: 'Sem conexão com a internet.',
        erro: true,
        concluido: true,
      );
      return;
    }

    _isSyncing = true;
    final logId = await _initSyncLog();

    try {
      yield const SyncProgress(mensagem: 'Enviando dados ao servidor...');
      final pendentes = await _syncQueue.getPending();

      int enviados = 0;
      int falhas = 0;
      int processados = 0;
      final total = pendentes.length;

      AppLogger.i('SyncManager: iniciando push de $total itens');

      for (final item in pendentes) {
        processados++;

        yield SyncProgress(
          total: total,
          processados: processados,
          enviados: enviados,
          falhas: falhas,
          mensagem: 'Enviando ${item.entidade} ($processados/$total)...',
        );

        final result = await _pushItem(item);

        result.fold(
          (failure) {
            falhas++;
            AppLogger.w('SyncManager: falha ao enviar ${item.id}: ${failure.message}');
          },
          (_) {
            enviados++;
          },
        );
      }

      yield SyncProgress(
        total: total,
        processados: processados,
        enviados: enviados,
        falhas: falhas,
        mensagem: 'Buscando atualizações do servidor...',
      );

      int recebidos = 0;
      final pullResult = await _pullUpdates();
      pullResult.fold(
        (failure) {
          AppLogger.w('SyncManager: erro no pull: ${failure.message}');
        },
        (count) {
          recebidos = count;
        },
      );

      await _syncQueue.cleanSynced();

      await _finalizeSyncLog(
        logId,
        enviados: enviados,
        recebidos: recebidos,
        falhas: falhas,
        resultado: falhas == 0 ? 'SUCCESS' : (enviados > 0 ? 'PARTIAL' : 'FAILED'),
      );

      yield SyncProgress(
        total: total,
        processados: processados,
        enviados: enviados,
        falhas: falhas,
        mensagem: falhas == 0
            ? 'Sincronização concluída! ✓'
            : 'Concluído com $falhas falha(s).',
        concluido: true,
        erro: falhas > 0 && enviados == 0,
      );

      AppLogger.i(
        'SyncManager: sync finalizado — '
        'enviados: $enviados, recebidos: $recebidos, falhas: $falhas',
      );
    } catch (e, stack) {
      AppLogger.e('SyncManager: erro inesperado', e, stack);
      await _finalizeSyncLog(logId, resultado: 'FAILED', mensagem: e.toString());

      yield SyncProgress(
        mensagem: 'Erro inesperado: ${e.toString()}',
        concluido: true,
        erro: true,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<Either<Failure, void>> _pushItem(SyncQueueItem item) async {
    try {
      Either<Failure, dynamic> result;

      switch (item.operacao) {
        case SyncOperation.create:
          final endpoint = _getEndpoint(item.entidade);
          result = await _apiClient.post(endpoint, data: item.payload);

        case SyncOperation.update:
          final endpoint = _getEndpointById(item.entidade, item.entidadeId);
          result = await _apiClient.put(endpoint, data: item.payload);

        case SyncOperation.delete:
          final endpoint = _getEndpointById(item.entidade, item.entidadeId);
          result = await _apiClient.delete(endpoint);
      }

      return result.fold(
        (failure) async {
          await _syncQueue.markAsFailed(item.id, failure.message);
          return Left(failure);
        },
        (_) async {
          await _syncQueue.markAsSynced(item.id);
          // Marca o registro local como sincronizado
          await _markLocalAsSynced(item.entidade, item.entidadeId);
          return const Right(null);
        },
      );
    } catch (e) {
      await _syncQueue.markAsFailed(item.id, e.toString());
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, int>> _pullUpdates() async {
    final lastSync = await _getLastSyncDate();

    final result = await _apiClient.get(
      ApiEndpoints.sync.pull,
      queryParams: {'since': lastSync},
    );

    return result.fold(
      (failure) => Left(failure),
      (data) async {
        int totalRecebidos = 0;

        if (data is Map<String, dynamic>) {
          for (final entry in data.entries) {
            final entidade = entry.key;
            final registros = entry.value as List<dynamic>;

            for (final registro in registros) {
              await _upsertLocal(entidade, registro as Map<String, dynamic>);
              totalRecebidos++;
            }
          }
        }

        await _saveLastSyncDate();

        AppLogger.i('SyncManager: $totalRecebidos registros recebidos no pull');
        return Right(totalRecebidos);
      },
    );
  }


  Future<void> _upsertLocal(String entidade, Map<String, dynamic> data) async {
    data['is_synced'] = 1;
    data['server_id'] = data['id'];
    data['atualizado_em'] = DateTime.now().toIso8601String();

    await _db.insert(entidade, data);
  }

  Future<void> _markLocalAsSynced(String entidade, String entidadeId) async {
    await _db.update(
      entidade,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [entidadeId],
    );
  }

  String _getEndpoint(String entidade) {
    const map = {
      'abastecimentos': '/abastecimentos',
      'leituras_chuva': '/leituras-chuva',
      'ajustes_estoque': '/ajustes-estoque',
    };
    return map[entidade] ?? '/$entidade';
  }

  String _getEndpointById(String entidade, String id) {
    return '${_getEndpoint(entidade)}/$id';
  }

  Future<String> _getLastSyncDate() async {
    final result = await _db.rawQuery(
      "SELECT MAX(finalizado_em) as last FROM sync_log WHERE resultado = 'SUCCESS'",
    );
    return result.first['last'] as String? ?? '2000-01-01T00:00:00';
  }

  Future<void> _saveLastSyncDate() async {
  }

  Future<String> _initSyncLog() async {
    const uuid = String.fromEnvironment('UUID', defaultValue: '');
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.insert('sync_log', {
      'id': id,
      'iniciado_em': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> _finalizeSyncLog(
    String logId, {
    int enviados = 0,
    int recebidos = 0,
    int falhas = 0,
    required String resultado,
    String? mensagem,
  }) async {
    await _db.update(
      'sync_log',
      {
        'finalizado_em': DateTime.now().toIso8601String(),
        'resultado': resultado,
        'enviados': enviados,
        'recebidos': recebidos,
        'falhas': falhas,
        'mensagem': mensagem,
      },
      where: 'id = ?',
      whereArgs: [logId],
    );
  }
}

