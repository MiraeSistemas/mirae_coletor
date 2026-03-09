// O QUE É ISSO?
// ------------
// Centraliza todos os endpoints da API em um único lugar.
// Assim, se uma rota mudar, você altera apenas aqui.
//
// PADRÃO USADO:
// A URL base (ex: https://servidor.mirae.com.br/api) é dinâmica
// porque cada cliente/fazenda pode ter seu próprio servidor.
// Os paths (ex: /auth/login) são fixos.
//
// Uso:
//   ApiEndpoints.auth.login
//   → '/auth/login'
//
//   ApiEndpoints.abastecimentos.list
//   → '/abastecimentos'

class ApiEndpoints {
  ApiEndpoints._();

  static const auth = _AuthEndpoints();
  static const sync = _SyncEndpoints();

  static const produtos           = _CrudEndpoints('/produtos');
  static const abastece           = _CrudEndpoints('/abastece');
  static const pluviometro        = _CrudEndpoints('/pluviometro');
  static const talhoes            = _CrudEndpoints('/talhoes');
  static const prodcombustivel    = _CrudEndpoints('/prodcombustivel');

}

class  _AuthEndpoints {
  const _AuthEndpoints();

  String get login => '/auth/login';
  String get logout => '/auth/logout';
  String get refreshToken => '/auth/refresh';
  String get healthCheck => 'health';
}

class _SyncEndpoints {
  const _SyncEndpoints();

  String get push => '/sync/push';
  String get pull => '/sync/pull';


}

class _CrudEndpoints {
  final String _base;
  const _CrudEndpoints(this._base);

  String get list => _base;
  String get create => _base;
  String byId(String id) => '$_base/$id';
  String update(String id) => '$_base/$id';
  String delete(String id) => '$_base/$id';

}
