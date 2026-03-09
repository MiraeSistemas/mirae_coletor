// PÁGINA PRINCIPAL — CARROSSEL DE MÓDULOS
// -----------------------------------------
// StatefulWidget porque precisamos:
//   1. Controlar qual card está no centro (índice atual)
//   2. Animar a entrada dos elementos (fade + slide)
//   3. Escutar mudanças de conectividade para o indicador
//
// PageController → controla um PageView ou carrossel.
//   viewportFraction: 0.6 → cada página ocupa 60% da tela,
//   mostrando as laterais dos cards adjacentes.
//
// WidgetsBindingObserver → permite escutar eventos do ciclo
// de vida do app (pause, resume, detach).

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../widgets/home/module_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  // Índice do card central no carrossel
  int _currentIndex = 0;

  // Controller de animação de entrada da página
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // PageController do carrossel nativo
  // viewportFraction: 0.72 → cada card ocupa 72% da tela,
  // deixando os adjacentes parcialmente visíveis nas laterais
  late PageController _pageController;

  // Conectividade
  final _connectivity = sl<ConnectivityService>();
  bool _isOnline = false;

  // -------------------------------------------------------
  // DEFINIÇÃO DOS MÓDULOS
  // Lista de ModuleData que alimenta o carrossel
  // -------------------------------------------------------
  final List<ModuleData> _modules = const [
    ModuleData(
      title: 'Abastecimento',
      subtitle: 'Controle de combustível',
      icon: Icons.local_gas_station_rounded,
      gradient: AppColors.gradientFuel,
      route: AppRoutes.abastecimento,
    ),
    ModuleData(
      title: 'Sincronizar',
      subtitle: 'Enviar e receber dados',
      icon: Icons.sync_rounded,
      gradient: AppColors.gradientSync,
      route: AppRoutes.sync,
      pendingCount: 0, // será atualizado dinamicamente
    ),
    ModuleData(
      title: 'Pluviômetro',
      subtitle: 'Leitura de chuva',
      icon: Icons.water_drop_rounded,
      gradient: AppColors.gradientBlue,
      route: AppRoutes.pluviometro,
    ),
    ModuleData(
      title: 'Estoque',
      subtitle: 'Inventário e ajustes',
      icon: Icons.inventory_2_rounded,
      gradient: AppColors.gradientStock,
      route: AppRoutes.estoque,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupEntrance();
    _setupConnectivity();
  }

  // Configura animação de entrada da página
  void _setupEntrance() {
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.72,
    );
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Inicia a animação com delay para dar tempo ao Flutter renderizar
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  // Escuta mudanças de conectividade
  void _setupConnectivity() {
    _isOnline = _connectivity.isConnected;
    _connectivity.connectionStream.listen((isOnline) {
      // setState() notifica o Flutter para reconstruir o widget
      if (mounted) setState(() => _isOnline = isOnline);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // SafeArea → respeita notch, barra de status e home indicator
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildConnectionIndicator(),
                const SizedBox(height: 32),
                _buildCarousel(),
                const SizedBox(height: 28),
                _buildIndicators(),
                const SizedBox(height: 32),
                _buildQuickInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // HEADER — Logo + saudação
  // -------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Logo Mirae em texto (até ter o asset da imagem)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mirae',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Sistemas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botão de perfil/configurações
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // INDICADOR DE CONEXÃO
  // -------------------------------------------------------
  Widget _buildConnectionIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // Muda de cor conforme o estado da conexão
          color: _isOnline ? AppColors.primarySubtle : AppColors.dangerSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isOnline
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ponto pulsante de status
            _ConnectionDot(isOnline: _isOnline),
            const SizedBox(width: 8),
            Text(
              _isOnline ? 'Online — dados sincronizados' : 'Offline — modo local ativo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isOnline ? AppColors.primary : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // CARROSSEL DE MÓDULOS — PageView nativo do Flutter
  // -------------------------------------------------------
  // Por que PageView em vez de carousel_slider?
  // O Flutter 3.19+ adicionou CarouselController nativo que
  // conflita com o pacote carousel_slider. O PageView resolve
  // tudo sem dependência externa e com controle total.
  //
  // PageController.viewportFraction → fração da tela por card
  //   0.72 → card central ocupa 72%, mostrando os vizinhos
  //
  // NotificationListener<ScrollNotification> → escuta o scroll
  // do PageView para atualizar _currentIndex de forma fluida,
  // mesmo durante o arrasto (antes de "encaixar" na página)
  Widget _buildCarousel() {
    return SizedBox(
      height: 300,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // ScrollUpdateNotification → disparada durante o arrasto
          if (notification is ScrollUpdateNotification) {
            // page retorna double (ex: 0.7 quando entre o card 0 e 1)
            // round() arredonda para o índice mais próximo
            final page = _pageController.page?.round() ?? 0;
            if (page != _currentIndex) {
              setState(() => _currentIndex = page);
            }
          }
          // retorna false para não bloquear a notificação
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          // itemCount null → scroll infinito
          // Para loop infinito usamos um truque: lista × 1000
          // e começamos no meio para poder ir para ambos os lados
          itemCount: null,
          onPageChanged: (rawIndex) {
            // Converte o índice "infinito" para o índice real da lista
            setState(() => _currentIndex = rawIndex % _modules.length);
          },
          itemBuilder: (context, rawIndex) {
            final index = rawIndex % _modules.length;
            final isCenter = _currentIndex == index;
            return Center(
              child: ModuleCard(
                module: _modules[index],
                isCenter: isCenter,
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // INDICADORES DE POSIÇÃO (dots)
  // -------------------------------------------------------
  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_modules.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            // Dot ativo: largo e colorido; inativo: pequeno e apagado
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // -------------------------------------------------------
  // INFORMAÇÕES RÁPIDAS — data e nome do módulo atual
  // -------------------------------------------------------
  Widget _buildQuickInfo() {
    final now = DateTime.now();
    // Formata a data manualmente (sem intl para simplicidade inicial)
    final months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final dateStr = '${now.day} ${months[now.month]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 12, color: AppColors.border),
          const SizedBox(width: 16),
          Text(
            _modules[_currentIndex].title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// WIDGET PRIVADO: ponto pulsante de conexão
// -------------------------------------------------------
// Widgets pequenos e específicos podem ser definidos no
// mesmo arquivo quando são usados apenas aqui.
class _ConnectionDot extends StatefulWidget {
  final bool isOnline;
  const _ConnectionDot({required this.isOnline});

  @override
  State<_ConnectionDot> createState() => _ConnectionDotState();
}

class _ConnectionDotState extends State<_ConnectionDot>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true); // repeat(reverse: true) → vai e volta em loop

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.isOnline ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.isOnline ? AppColors.primary : AppColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
