// O QUE É ISSO?
// ------------
// Ponto central de acesso ao banco SQLite local.
// Implementa o padrão Singleton: garante que existe
// apenas UMA instância do banco em toda a vida do app.
//
// CONCEITOS DART:
// ---------------
// static → pertence à classe, não à instância
// late   → variável que será inicializada depois (lazy)
// ??=    → "atribua somente se for null"
//          ex: _db ??= await _init()
//              → se _db for null, inicializa; senão, usa o existente
//
// PADRÃO SINGLETON EM DART:
// --------------------------
// class MinhaClasse {
//   static final MinhaClasse instance = MinhaClasse._internal();
//   MinhaClasse._internal();  // construtor privado
// }
// Uso: MinhaClasse.instance.metodo()

import 'package:mirae_coletor/core/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migrations/migration_v1.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  static const int _dbVersion = 1;

  static const String _dbName = 'mirae_app.db';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, _dbName);

    AppLogger.i('DatabaseHelper: abrindo banco em $path');

    return await openDatabase(
      path,
      version: _dbVersion,

      onCreate: (db, version) async {
        AppLogger.i('DatabaseHelper: criando banco v$version');
        await MigrationV1.create(db);
        AppLogger.i('DatabaseHelper: banco criado com sucesso');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.i(
          'DatabaseHelper: atualizando banco v$oldVersion → v$newVersion',
        );
      },

      onOpen: (db) {
        AppLogger.d('DatabaseHelper: banco aberto');
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }


  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }


  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $table'
      '${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      AppLogger.d('DatabaseHelper: banco fechado');
    }
  }
}

