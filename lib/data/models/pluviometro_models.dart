// MODELOS DE DADOS DO PLUVIÔMETRO
// ----------------------------------
// Models são classes que representam os dados como trafegam
// no app: entre banco local, API e UI.
//
// PADRÃO USADO:
// fromMap(Map)  → converte linha do SQLite em objeto Dart
// toMap()       → converte objeto Dart em linha para o SQLite
// fromJson(Map) → converte resposta da API em objeto Dart
// toJson()      → converte objeto para enviar à API
//
// Por que separar fromMap e fromJson?
// O banco local pode ter campos diferentes da API
// (ex: 'is_synced' existe só localmente).

class TalhaoModel {
  final String id;
  final String? serverId;
  final String nome;
  final double? areaHa;
  final String? descricao;
  final bool ativo;
  final bool isSynced;

  const TalhaoModel({
    required this.id,
    this.serverId,
    required this.nome,
    this.areaHa,
    this.descricao,
    this.ativo = true,
    this.isSynced = false,
  });

  factory TalhaoModel.fromMap(Map<String, dynamic> map) {
    return TalhaoModel(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      nome: map['nome'] as String,
      // as double? → cast opcional (pode ser null)
      areaHa: (map['area_ha'] as num?)?.toDouble(),
      descricao: map['descricao'] as String?,
      // SQLite armazena bool como INTEGER (0 ou 1)
      // == 1 converte para bool
      ativo: (map['ativo'] as int) == 1,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}

// -------------------------------------------------------
class PontoCapturaModel {
  final String id;
  final String? serverId;
  final String talhaoId;
  final String nome;
  final double? latitude;
  final double? longitude;
  final bool ativo;
  final bool isSynced;

  const PontoCapturaModel({
    required this.id,
    this.serverId,
    required this.talhaoId,
    required this.nome,
    this.latitude,
    this.longitude,
    this.ativo = true,
    this.isSynced = false,
  });

  factory PontoCapturaModel.fromMap(Map<String, dynamic> map) {
    return PontoCapturaModel(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      talhaoId: map['talhao_id'] as String,
      nome: map['nome'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      ativo: (map['ativo'] as int) == 1,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}

// -------------------------------------------------------
class LeituraChuvaModel {
  final String id;
  final String? serverId;
  final String pontoCapturaId;
  final String operadorId;
  final double valorMm;
  final DateTime dataHora;
  final String? observacao;
  final bool isSynced;

  const LeituraChuvaModel({
    required this.id,
    this.serverId,
    required this.pontoCapturaId,
    required this.operadorId,
    required this.valorMm,
    required this.dataHora,
    this.observacao,
    this.isSynced = false,
  });

  // -------------------------------------------------------
  // fromMap → do banco local
  // -------------------------------------------------------
  factory LeituraChuvaModel.fromMap(Map<String, dynamic> map) {
    return LeituraChuvaModel(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      pontoCapturaId: map['ponto_captura_id'] as String,
      operadorId: map['operador_id'] as String,
      valorMm: (map['valor_mm'] as num).toDouble(),
      // DateTime.parse() converte string ISO 8601 em DateTime
      dataHora: DateTime.parse(map['data_hora'] as String),
      observacao: map['observacao'] as String?,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  // -------------------------------------------------------
  // toMap → para inserir no banco local
  // -------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'ponto_captura_id': pontoCapturaId,
      'operador_id': operadorId,
      'valor_mm': valorMm,
      // toIso8601String() → '2024-10-24T08:00:00.000'
      'data_hora': dataHora.toIso8601String(),
      'observacao': observacao,
      // bool → int para SQLite: true=1, false=0
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // -------------------------------------------------------
  // toJson → para enviar à API
  // -------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ponto_captura_id': pontoCapturaId,
      'valor_mm': valorMm,
      'data_hora': dataHora.toIso8601String(),
      'observacao': observacao,
    };
  }

  // -------------------------------------------------------
  // copyWith → cria uma cópia com campos alterados
  // Padrão imutável: nunca muta o objeto, cria um novo
  // -------------------------------------------------------
  LeituraChuvaModel copyWith({
    String? serverId,
    bool? isSynced,
  }) {
    return LeituraChuvaModel(
      id: id,
      serverId: serverId ?? this.serverId,
      pontoCapturaId: pontoCapturaId,
      operadorId: operadorId,
      valorMm: valorMm,
      dataHora: dataHora,
      observacao: observacao,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}



