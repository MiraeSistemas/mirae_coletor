// O QUE É ISSO?
// ------------
// A fila de sincronização é o coração do sistema offline-first.
// Toda operação realizada offline (criar abastecimento, lançar chuva,
// ajustar estoque) é registrada aqui antes de ir ao servidor.
//
// FLUXO:
// Usuário cria registro → salva no SQLite local → enfileira na sync_queue
//    ↓ (quando online)
// SyncManager processa a fila → envia ao servidor → marca como SYNCED
//
// ESTADOS:
// PENDING → ainda não enviado ao servidor
// SYNCED  → enviado e confirmado com sucesso
// FAILED  → falhou após N tentativas (precisa de ação manual)

import 'dart:convert';
import 'package:mirae_coletor/core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';

enum SyncStatus { pending, synced, failed }

enum SyncOperation { create, update, delete }

class SyncQueueItem {
  final String id;
  final String entidade;       // nome da tabela (ex: 'abastecimentos')
  final String entidadeId;     // UUID do registro
  final SyncOperation operacao;
  final Map<String, dynamic> payload; // dados completos do registro
  final SyncStatus status;
  final int tentativas;
  final String? ultimoErro;
  final DateTime criadoEm;
  final DateTime? sincronizadoEm;

  const SyncQueueItem({
    required this.id,
    required this.entidade,
    required this.entidadeId,
    required this.operacao,
    required this.payload,
    this.status = SyncStatus.pending,
    this.tentativas = 0,
    this.ultimoErro,
    required this.criadoEm,
    this.sincronizadoEm,
  });

 factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      entidade: map['entidade'] as String,
      entidadeId: map['entidade_id'] as String,
      // Converte string do banco em enum
      operacao: SyncOperation.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['operacao'] as String).toUpperCase(),
      ),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      status: SyncStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['status'] as String).toUpperCase(),
      ),
      tentativas: map['tentativas'] as int,
      ultimoErro: map['ultimo_erro'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      sincronizadoEm: map['sincronizado_em'] != null
          ? DateTime.parse(map['sincronizado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entidade': entidade,
      'entidade_id': entidadeId,
      'operacao': operacao.name.toUpperCase(),
      'payload': jsonEncode(payload),
      'status': status.name.toUpperCase(),
      'tentativas': tentativas,
      'ultimo_erro': ultimoErro,
      'criado_em': criadoEm.toIso8601String(),
      'sincronizado_em': sincronizadoEm?.toIso8601String(),
    };
  }

  SyncQueueItem copyWith({
    SyncStatus? status,
    int? tentativas,
    String? ultimoErro,
    DateTime? sincronizadoEm,
  }) {
    return SyncQueueItem(
      id: id,
      entidade: entidade,
      entidadeId: entidadeId,
      operacao: operacao,
      payload: payload,
      status: status ?? this.status,
      tentativas: tentativas ?? this.tentativas,
      ultimoErro: ultimoErro ?? this.ultimoErro,
      criadoEm: criadoEm,
      sincronizadoEm: sincronizadoEm ?? this.sincronizadoEm,
    );
  }
}

class SyncQueue {
  final DatabaseHelper _db;
  final _uuid = const Uuid();

  static const String _table = 'sync_queue';
  static const int _maxTentativas = 3;

  SyncQueue({required DatabaseHelper db}) : _db = db;

 Future<void> enqueue({
    required String entidade,
    required String entidadeId,
    required SyncOperation operacao,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueItem(
      id: _uuid.v4(),
      entidade: entidade,
      entidadeId: entidadeId,
      operacao: operacao,
      payload: payload,
      criadoEm: DateTime.now(),
    );

    await _db.insert(_table, item.toMap());

    AppLogger.d(
      'SyncQueue: enfileirado ${operacao.name.toUpperCase()} '
      '[$entidade#$entidadeId]',
    );
  }

 Future<List<SyncQueueItem>> getPending() async {
    final maps = await _db.query(
      _table,
      where: 'status = ? AND tentativas < ?',
      whereArgs: ['PENDING', _maxTentativas],
      orderBy: 'criado_em ASC',
    );
    return maps.map(SyncQueueItem.fromMap).toList();
  }

  Future<int> countPending() async {
    return await _db.count(
      _table,
      where: 'status = ? AND tentativas < ?',
      whereArgs: ['PENDING', _maxTentativas],
    );
  }

  Future<int> countFailed() async {
    return await _db.count(
      _table,
      where: 'status = ? OR tentativas >= ?',
      whereArgs: ['FAILED', _maxTentativas],
    );
  }

 Future<void> markAsSynced(String id) async {
    await _db.update(
      _table,
      {
        'status': 'SYNCED',
        'sincronizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

 Future<void> markAsFailed(String id, String errorMessage) async {
    final maps = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return;

    final item = SyncQueueItem.fromMap(maps.first);
    final novasTentativas = item.tentativas + 1;

    await _db.update(
      _table,
      {
        'tentativas': novasTentativas,
        'ultimo_erro': errorMessage,
        if (novasTentativas >= _maxTentativas) 'status': 'FAILED',
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    AppLogger.w(
      'SyncQueue: falha registrada para $id '
      '(tentativa $novasTentativas/$_maxTentativas): $errorMessage',
    );
  }

 Future<void> cleanSynced() async {
    final deleted = await _db.delete(
      _table,
      where: 'status = ?',
      whereArgs: ['SYNCED'],
    );
    AppLogger.i('SyncQueue: $deleted itens sincronizados removidos');
  }

  Future<void> retryFailed() async {
    await _db.rawQuery('''
      UPDATE $_table
      SET status = 'PENDING', tentativas = 0, ultimo_erro = NULL
      WHERE status = 'FAILED'
    ''');
    AppLogger.i('SyncQueue: itens com falha resetados para PENDING');
  }
}

