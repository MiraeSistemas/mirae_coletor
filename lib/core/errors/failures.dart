// O QUE É ISSO?
// ------------
// Em vez de lançar exceções (throw Exception) que podem
// não ser tratadas, usamos o tipo Either<Failure, T> do dartz.
// Toda operação que pode falhar retorna:
//   - Left(AlgumaFailure())  → algo deu errado
//   - Right(dadosRetornados) → sucesso
//
// Isso força o chamador a tratar o erro explicitamente.

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType : $message';

}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Sem conexão com a internet.');
}

class TimeoutFailure extends Failure {
  const TimeoutFailure() : super('A requisição excedeu o tempo limite.');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Usuario não localizado.']);
}

class ServerUrlFailure extends Failure {
  const ServerUrlFailure([super.message = 'A requisição excedeu o tempo limite.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Registro não encontrado.']);
}


class SyncFailure extends Failure {
  final int pendingItems;
  const SyncFailure(super.message, {this.pendingItems = 0});
}

class QrCodeNotFoundFailure extends Failure {
  const QrCodeNotFoundFailure([super.message = 'Produto não encontrado para este QR Code.']);
}

class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Não foi possível acessar a câmera.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Ocorreu um erro inesperado.']);
}

