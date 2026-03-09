// TELA DO PLUVIÔMETRO
// ---------------------
// BlocProvider → cria e injeta o Cubit na árvore de widgets.
//   Todos os filhos podem acessar com context.read<PluviometroCubit>()
//
// BlocConsumer → combina BlocBuilder + BlocListener:
//   builder  → reconstrói a UI quando o estado muda
//   listener → executa ações colaterais (snackbar, navegar)
//              sem reconstruir a UI
//
// BlocBuilder → reconstrói APENAS quando o estado muda
// context.read<Cubit>()  → lê o Cubit SEM escutar mudanças (para chamadas)
// context.watch<Cubit>() → lê E escuta mudanças (em build())

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pluviometro_models.dart';
import '../../../data/repositories/pluviometro_repository.dart';
import '../../widgets/shared/mirae_card.dart';
import 'pluviometro_cubit.dart';

class PluviometroPage extends StatelessWidget {
  const PluviometroPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocProvider cria o Cubit e o disponibiliza para toda a subárvore
    return BlocProvider(
      // create é chamado uma vez e retorna o Cubit criado
      create: (_) => PluviometroCubit(
        repository: PluviometroRepository(
          db: sl(),
          syncQueue: sl(),
        ),
      )..carregar(), // '..' cascade operator: chama carregar() no Cubit recém criado
      child: const _PluviometroView(),
    );
  }
}

// -------------------------------------------------------
// VIEW SEPARADA
// Boa prática: separar BlocProvider (PluviometroPage)
// da view que usa o Cubit (_PluviometroView).
// Facilita testes unitários da view.
// -------------------------------------------------------
class _PluviometroView extends StatefulWidget {
  const _PluviometroView();

  @override
  State<_PluviometroView> createState() => _PluviometroViewState();
}

class _PluviometroViewState extends State<_PluviometroView> {
  // Controller do campo de entrada de valor
  final _valorController = TextEditingController();

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PLUVIÔMETRO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // BlocConsumer: builder + listener em um único widget
      body: BlocConsumer<PluviometroCubit, PluviometroState>(
        // listener: reage a estados sem reconstruir
        listener: (context, state) {
          if (state is PluviometroSalvoComSucesso) {
            _valorController.clear();
            _showSuccessSnackbar(context, state.valorMm);
          }
          if (state is PluviometroError) {
            _showErrorSnackbar(context, state.message);
          }
        },
        // builder: constrói a UI baseado no estado atual
        builder: (context, state) {
          // switch em sealed class → exaustivo (sem necessidade de default)
          return switch (state) {
            PluviometroInitial() => const _LoadingView(),
            PluviometroLoading() => const _LoadingView(),
            PluviometroLoaded() => _LoadedView(
                state: state,
                valorController: _valorController,
              ),
            PluviometroError() => _ErrorView(message: state.message),
            // Sucesso é tratado no listener, o builder mostra loading
            PluviometroSalvoComSucesso() => const _LoadingView(),
          };
        },
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, double valor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Leitura de ${valor.toStringAsFixed(1)} mm salva!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// -------------------------------------------------------
// ESTADO: LOADING
// -------------------------------------------------------
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.blue),
    );
  }
}

// -------------------------------------------------------
// ESTADO: ERRO
// -------------------------------------------------------
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.read<PluviometroCubit>().carregar(),
            child: const Text('Tentar novamente',
                style: TextStyle(color: AppColors.blue)),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// ESTADO: CARREGADO
// -------------------------------------------------------
class _LoadedView extends StatelessWidget {
  final PluviometroLoaded state;
  final TextEditingController valorController;

  const _LoadedView({required this.state, required this.valorController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // physics: como o scroll se comporta ao atingir o limite
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeletores(context),
          const SizedBox(height: 16),
          _buildCardLeituraAtual(),
          const SizedBox(height: 16),
          _buildEntradaLeitura(context),
          const SizedBox(height: 24),
          _buildHistorico(),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // SELETORES DE TALHÃO E PONTO
  // -------------------------------------------------------
  Widget _buildSeletores(BuildContext context) {
    final cubit = context.read<PluviometroCubit>();

    return Row(
      children: [
        // Seletor de Talhão
        Expanded(
          child: _buildDropdown<TalhaoModel>(
            label: 'Talhão',
            value: state.talhaoSelecionado,
            items: state.talhoes,
            itemLabel: (t) => t.nome,
            onChanged: (t) => cubit.selecionarTalhao(t!),
          ),
        ),
        const SizedBox(width: 12),
        // Seletor de Ponto de Captura
        Expanded(
          child: _buildDropdown<PontoCapturaModel>(
            label: 'Ponto',
            value: state.pontoSelecionado,
            items: state.pontos,
            itemLabel: (p) => p.nome,
            onChanged: state.pontos.isEmpty
                ? null
                : (p) => cubit.selecionarPonto(p!),
          ),
        ),
      ],
    );
  }

  // Widget genérico de dropdown reutilizável
  // T é um tipo genérico → funciona com TalhaoModel, PontoCapturaModel etc.
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        // Esconde a linha padrão do DropdownButton
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(label,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 13)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          dropdownColor: AppColors.surfaceElevated,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // CARD DE LEITURA ATUAL
  // -------------------------------------------------------
  Widget _buildCardLeituraAtual() {
    return MiraeCard(
      gradient: AppColors.gradientBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leitura Atual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Valor principal em display grande
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.totalAtual.toStringAsFixed(1),
                style: AppTextStyles.displayHero.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'mm',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtros de período
          _buildFiltrosPeriodo(),
        ],
      ),
    );
  }

  Widget _buildFiltrosPeriodo() {
    return Builder(builder: (context) {
      return Row(
        children: PeriodoFiltro.values.map((periodo) {
          final isSelected = state.periodoSelecionado == periodo;
          return GestureDetector(
            onTap: () => context.read<PluviometroCubit>().mudarPeriodo(periodo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                periodo.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.blue : Colors.white70,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // -------------------------------------------------------
  // ENTRADA DE NOVA LEITURA
  // -------------------------------------------------------
  Widget _buildEntradaLeitura(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Nova Leitura',
          icon: Icons.add_circle_outline_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: valorController,
                // keyboardType numérico com casas decimais
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: '0.0',
                  suffixText: 'mm',
                  suffixStyle: TextStyle(
                      color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.salvando
                    ? null
                    : () => _salvarLeitura(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _salvarLeitura(BuildContext context) {
    final texto = valorController.text.trim().replaceAll(',', '.');
    // tryParse retorna null se não for um número válido
    final valor = double.tryParse(texto);

    if (valor == null || valor < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido em mm'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // 'TODO: pegar operador do usuário logado'
    context.read<PluviometroCubit>().salvarLeitura(
          operadorId: 'usuario-atual', // substituir pelo auth
          valorMm: valor,
        );
  }

  // -------------------------------------------------------
  // HISTÓRICO DE LEITURAS
  // -------------------------------------------------------
  Widget _buildHistorico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Histórico Recente',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),

        if (state.historico.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Nenhuma leitura no período selecionado',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            ),
          )
        else
          // ListView.separated cria lista com separadores entre itens
          // shrinkWrap: true → lista ocupa apenas o espaço dos itens
          // physics: NeverScroll → desabilita scroll da lista (o pai já faz)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.historico.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final leitura = state.historico[index];
              return _HistoricoItem(leitura: leitura);
            },
          ),
      ],
    );
  }
}

// -------------------------------------------------------
// ITEM DE HISTÓRICO
// -------------------------------------------------------
class _HistoricoItem extends StatelessWidget {
  final LeituraChuvaModel leitura;
  const _HistoricoItem({required this.leitura});

  @override
  Widget build(BuildContext context) {
    // DateFormat do pacote intl formata datas de forma localizada
    final dateFormat = DateFormat('EEE, dd MMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final isToday = _isToday(leitura.dataHora);

    return HistoryItem(
      title: isToday ? 'Hoje' : dateFormat.format(leitura.dataHora),
      subtitle: timeFormat.format(leitura.dataHora),
      value: '${leitura.valorMm.toStringAsFixed(1)} mm',
      icon: Icons.calendar_today_rounded,
      // Valor em azul (cor do pluviômetro)
      valueColor: AppColors.blueLight,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
