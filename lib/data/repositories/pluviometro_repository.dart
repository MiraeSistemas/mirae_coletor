// REPOSITÓRIO DO PLUVIÔMETRO
// ----------------------------
// O repositório é a camada que abstrai de ONDE os dados vêm.
// A UI não sabe se os dados vieram do SQLite ou da API —
// ela só chama o repositório e recebe os dados.
//
// PADRÃO REPOSITORY:
// UI → Repository → (LocalDataSource OU RemoteDataSource)
//
// OFFLINE FIRST:
// - Leituras: sempre do banco local (rápido, sem internet)
// - Gravações: banco local + sync_queue (envia quando online)
// - Pull: busca dados do servidor para atualizar o local

import 'package:dartz/dartz.dart';
import 'package:mirae_coletor/core/utils/logger.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/errors/failures.dart';
import '../../core/sync/sync_queue.dart';
import '../models/pluviometro_models.dart';

class PluviometroRepository {
  final DatabaseHelper _db;
  final SyncQueue _syncQueue;
  final _uuid = const Uuid();

  PluviometroRepository({
    required DatabaseHelper db,
    required SyncQueue syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  // -------------------------------------------------------
  // TALHÕES
  // -------------------------------------------------------

  /// Retorna todos os talhões ativos
  Future<Either<Failure, List<TalhaoModel>>> getTalhoes() async {
    try {
      final maps = await _db.query(
        'talhoes',
        where: 'ativo = ?',
        whereArgs: [1],
        orderBy: 'nome ASC',
      );
      // .map() transforma cada Map em TalhaoModel
      // .toList() converte o Iterable em List
      final talhoes = maps.map(TalhaoModel.fromMap).toList();
      return Right(talhoes);
    } catch (e, stack) {
      AppLogger.e('PluviometroRepository.getTalhoes', e, stack);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // -------------------------------------------------------
  // PONTOS DE CAPTURA
  // -------------------------------------------------------

  /// Retorna os pontos de captura de um talhão específico
  Future<Either<Failure, List<PontoCapturaModel>>> getPontosByTalhao(
    String talhaoId,
  ) async {
    try {
      final maps = await _db.query(
        'pontos_captura',
        where: 'talhao_id = ? AND ativo = ?',
        // whereArgs usa List<dynamic> — os '?' são substituídos em ordem
        whereArgs: [talhaoId, 1],
        orderBy: 'nome ASC',
      );
      return Right(maps.map(PontoCapturaModel.fromMap).toList());
    } catch (e, stack) {
      AppLogger.e('PluviometroRepository.getPontosByTalhao', e, stack);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // -------------------------------------------------------
  // LEITURAS
  // -------------------------------------------------------

  /// Salva uma nova leitura de chuva localmente e enfileira para sync
  Future<Either<Failure, LeituraChuvaModel>> salvarLeitura({
    required String pontoCapturaId,
    required String operadorId,
    required double valorMm,
    String? observacao,
  }) async {
    try {
      final leitura = LeituraChuvaModel(
        // uuid.v4() gera um ID único universal
        // ex: '550e8400-e29b-41d4-a716-446655440000'
        id: _uuid.v4(),
        pontoCapturaId: pontoCapturaId,
        operadorId: operadorId,
        valorMm: valorMm,
        dataHora: DateTime.now(),
        observacao: observacao,
        isSynced: false,
      );

      // Salva no banco local
      await _db.insert('leituras_chuva', leitura.toMap());

      // Enfileira para sincronização
      await _syncQueue.enqueue(
        entidade: 'leituras_chuva',
        entidadeId: leitura.id,
        operacao: SyncOperation.create,
        payload: leitura.toJson(),
      );

      AppLogger.i('PluviometroRepository: leitura salva [${leitura.id}]');
      return Right(leitura);
    } catch (e, stack) {
      AppLogger.e('PluviometroRepository.salvarLeitura', e, stack);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  /// Busca o histórico de leituras de um ponto de captura
  Future<Either<Failure, List<LeituraChuvaModel>>> getHistorico({
    required String pontoCapturaId,
    DateTime? desde,
  }) async {
    try {
      // Monta a query dinamicamente com base nos filtros
      String where = 'ponto_captura_id = ?';
      List<dynamic> whereArgs = [pontoCapturaId];

      if (desde != null) {
        where += ' AND data_hora >= ?';
        whereArgs.add(desde.toIso8601String());
      }

      final maps = await _db.query(
        'leituras_chuva',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'data_hora DESC',
      );

      return Right(maps.map(LeituraChuvaModel.fromMap).toList());
    } catch (e, stack) {
      AppLogger.e('PluviometroRepository.getHistorico', e, stack);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  /// Soma total de chuva de um ponto em um período
  Future<Either<Failure, double>> getTotalPeriodo({
    required String pontoCapturaId,
    required DateTime desde,
  }) async {
    try {
      final result = await _db.rawQuery('''
        SELECT COALESCE(SUM(valor_mm), 0) as total
        FROM leituras_chuva
        WHERE ponto_captura_id = ?
          AND data_hora >= ?
      ''', [pontoCapturaId, desde.toIso8601String()]);

      // COALESCE retorna 0 se não houver registros
      final total = (result.first['total'] as num).toDouble();
      return Right(total);
    } catch (e, stack) {
      AppLogger.e('PluviometroRepository.getTotalPeriodo', e, stack);
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
