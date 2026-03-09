// GERENCIAMENTO DE ESTADO COM CUBIT
// -----------------------------------
// Cubit é uma versão simplificada do BLoC (Business Logic Component).
//
// CUBIT vs BLOC:
// BLoC:  UI → Event → BLoC → State → UI  (mais verboso, para fluxos complexos)
// Cubit: UI → método() → Cubit → State → UI  (mais simples e direto)
//
// COMO FUNCIONA:
// 1. PluviometroCubit estende Cubit<PluviometroState>
// 2. O estado inicial é passado no super()
// 3. emit(NovoEstado()) → notifica todos os ouvintes (widgets)
// 4. BlocBuilder na UI reconstrói quando o estado muda
//
// ESTADOS:
// PluviometroInitial   → estado inicial (nunca carregado)
// PluviometroLoading   → carregando dados
// PluviometroLoaded    → dados disponíveis
// PluviometroError     → algo deu errado
// PluviometroSaving    → salvando nova leitura

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/pluviometro_models.dart';
import '../../../data/repositories/pluviometro_repository.dart';
import 'package:mirae_coletor/core/utils/logger.dart';

sealed class PluviometroState {}

class PluviometroInitial extends PluviometroState {}

class PluviometroLoading extends PluviometroState {}

class PluviometroLoaded extends PluviometroState {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? talhaoSelecionado;
  final List<PontoCapturaModel> pontos;
  final PontoCapturaModel? pontoSelecionado;
  final List<LeituraChuvaModel> historico;
  final double totalAtual; // mm no período selecionado
  final PeriodoFiltro periodoSelecionado;
  final bool salvando; // true enquanto salva nova leitura

  PluviometroLoaded({
    required this.talhoes,
    this.talhaoSelecionado,
    required this.pontos,
    this.pontoSelecionado,
    required this.historico,
    this.totalAtual = 0.0,
    this.periodoSelecionado = PeriodoFiltro.h24,
    this.salvando = false,
  });

  PluviometroLoaded copyWith({
    List<TalhaoModel>? talhoes,
    TalhaoModel? talhaoSelecionado,
    List<PontoCapturaModel>? pontos,
    PontoCapturaModel? pontoSelecionado,
    List<LeituraChuvaModel>? historico,
    double? totalAtual,
    PeriodoFiltro? periodoSelecionado,
    bool? salvando,
  }) {
    return PluviometroLoaded(
      talhoes: talhoes ?? this.talhoes,
      talhaoSelecionado: talhaoSelecionado ?? this.talhaoSelecionado,
      pontos: pontos ?? this.pontos,
      pontoSelecionado: pontoSelecionado ?? this.pontoSelecionado,
      historico: historico ?? this.historico,
      totalAtual: totalAtual ?? this.totalAtual,
      periodoSelecionado: periodoSelecionado ?? this.periodoSelecionado,
      salvando: salvando ?? this.salvando,
    );
  }
}

class PluviometroError extends PluviometroState {
  final String message;
  PluviometroError(this.message);
}

class PluviometroSalvoComSucesso extends PluviometroState {
  final double valorMm;
  PluviometroSalvoComSucesso(this.valorMm);
}

enum PeriodoFiltro {
  h1('1h', Duration(hours: 1)),
  h24('24h', Duration(hours: 24)),
  d7('7d', Duration(days: 7)),
  d30('30d', Duration(days: 30));

  final String label;
  final Duration duration;
  const PeriodoFiltro(this.label, this.duration);
}

class PluviometroCubit extends Cubit<PluviometroState> {
  final PluviometroRepository _repository;

  PluviometroCubit({required PluviometroRepository repository})
      : _repository = repository,
        super(PluviometroInitial());

  Future<void> carregar() async {
    emit(PluviometroLoading());

    final result = await _repository.getTalhoes();

    result.fold(
      (failure) => emit(PluviometroError(failure.message)),
      (talhoes) {
        emit(PluviometroLoaded(
          talhoes: talhoes,
          pontos: [],
          historico: [],
        ));
        if (talhoes.isNotEmpty) {
          selecionarTalhao(talhoes.first);
        }
      },
    );
  }

  Future<void> selecionarTalhao(TalhaoModel talhao) async {
    final current = state;
    if (current is! PluviometroLoaded) return;

    emit(current.copyWith(
      talhaoSelecionado: talhao,
      pontos: [],
      pontoSelecionado: null,
      historico: [],
      totalAtual: 0.0,
    ));

    final result = await _repository.getPontosByTalhao(talhao.id);

    result.fold(
      (failure) => emit(PluviometroError(failure.message)),
      (pontos) {
        final loaded = state as PluviometroLoaded;
        emit(loaded.copyWith(pontos: pontos));

        if (pontos.isNotEmpty) selecionarPonto(pontos.first);
      },
    );
  }

  Future<void> selecionarPonto(PontoCapturaModel ponto) async {
    final current = state;
    if (current is! PluviometroLoaded) return;

    emit(current.copyWith(pontoSelecionado: ponto));
    await _carregarHistoricoETotal(ponto.id, current.periodoSelecionado);
  }

  Future<void> mudarPeriodo(PeriodoFiltro periodo) async {
    final current = state;
    if (current is! PluviometroLoaded) return;
    if (current.pontoSelecionado == null) return;

    emit(current.copyWith(periodoSelecionado: periodo));
    await _carregarHistoricoETotal(current.pontoSelecionado!.id, periodo);
  }

  Future<void> _carregarHistoricoETotal(
    String pontoId,
    PeriodoFiltro periodo,
  ) async {
    final current = state;
    if (current is! PluviometroLoaded) return;

    final desde = DateTime.now().subtract(periodo.duration);

    final results = await Future.wait([
      _repository.getHistorico(pontoCapturaId: pontoId, desde: desde),
      _repository.getTotalPeriodo(pontoCapturaId: pontoId, desde: desde),
    ]);

    final historicoResult = results[0] as dynamic;
    final totalResult = results[1] as dynamic;

    historicoResult.fold(
      (failure) => emit(PluviometroError(failure.message)),
      (historico) {
        totalResult.fold(
          (failure) => emit(PluviometroError(failure.message)),
          (total) {
            final loaded = state as PluviometroLoaded;
            emit(loaded.copyWith(
              historico: historico,
              totalAtual: total,
            ));
          },
        );
      },
    );
  }

  Future<void> salvarLeitura({
    required String operadorId,
    required double valorMm,
    String? observacao,
  }) async {
    final current = state;
    if (current is! PluviometroLoaded) return;
    if (current.pontoSelecionado == null) return;

    emit(current.copyWith(salvando: true));

    final result = await _repository.salvarLeitura(
      pontoCapturaId: current.pontoSelecionado!.id,
      operadorId: operadorId,
      valorMm: valorMm,
      observacao: observacao,
    );

    result.fold(
      (failure) {
        AppLogger.e('PluviometroCubit.salvarLeitura', failure.message);
        emit(current.copyWith(salvando: false));
        emit(PluviometroError(failure.message));
      },
      (leitura) {
        emit(PluviometroSalvoComSucesso(leitura.valorMm));
        carregar();
      },
    );
  }
}
