// O QUE É ISSO?
// ------------
// Migration: script SQL que cria a estrutura inicial do banco.
// Quando o banco é criado pela primeira vez (onCreate),
// este script é executado.
//
// VERSIONAMENTO:
// Se precisar alterar o schema no futuro (adicionar coluna, tabela),
// crie migration_v2.dart e chame-a no onUpgrade do DatabaseHelper.
//
// TIPOS DE DADOS NO SQLITE:
// -------------------------
// INTEGER → números inteiros (int no Dart)
// REAL    → números decimais (double no Dart)
// TEXT    → texto (String no Dart)
// BLOB    → dados binários (Uint8List no Dart)
// (SQLite não tem BOOLEAN ou DATETIME nativos — use INTEGER e TEXT)
//
// RESTRIÇÕES COMUNS:
// PRIMARY KEY   → identificador único da linha
// NOT NULL      → campo obrigatório
// DEFAULT valor → valor padrão se não informado
// REFERENCES    → chave estrangeira (relacionamento)

import 'package:sqflite/sqflite.dart';

class MigrationV1 {
  static Future<void> create(Database db) async {
    final batch = db.batch();

    _createUsuarios(batch);
    _createProdutos(batch);
    _createTalhaos(batch);
    _createPluviometro(batch);
    _createAbastece(batch);


    await batch.commit(noResult: true);


  }
  

  static void _createUsuarios(Batch batch) {
    batch.execute('''
    CREATE TABLE usuarios (
        id          INTEGER PRIMARY KEY,
    )

    ''');
  } 
  static void _createProdutos(Batch batch) {
    batch.execute('''
    CREATE TABLE produtos (
        id          INTEGER PRIMARY KEY,
    )

    ''');
  } 
  static void _createTalhaos(Batch batch) {
    batch.execute('''
    CREATE TABLE talhao (
        id          INTEGER PRIMARY KEY,
    )

    ''');
  } 
  static void _createPluviometro(Batch batch) {
    batch.execute('''
    CREATE TABLE pluviometro (
        id          INTEGER PRIMARY KEY,
    )

    ''');
  } 
  static void _createAbastece(Batch batch) {
    batch.execute('''
    CREATE TABLE abastece (
        id          INTEGER PRIMARY KEY,
    )

    ''');
  } 
}
