// CARD DO MÓDULO NO CARROSSEL
// ----------------------------
// Cada card representa um módulo do app (Abastecimento,
// Pluviômetro, etc.) com gradiente único, ícone animado
// e badge de itens pendentes.
//
// StatefulWidget → tem estado interno que pode mudar.
// Usado aqui para a animação de scale no tap (efeito de press).
//
// AnimationController → controla o progresso de uma animação
//   - vsync: this → sincroniza com o frame rate da tela
//   - TickerProviderStateMixin → fornece o 'vsync'
//
// Tween<double>(begin: 1.0, end: 0.96)
//   → anima um double de 1.0 a 0.96 (efeito de "apertar")

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final int pendingCount; // badge de pendências

  const ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    this.pendingCount = 0,
  });
}

class ModuleCard extends StatefulWidget {
  final ModuleData module;
  final bool isCenter; // o card central tem escala maior

  const ModuleCard({
    super.key,
    required this.module,
    this.isCenter = false,
  });

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this, // 'this' funciona como vsync por causa do Mixin
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // SEMPRE dispose controllers para liberar memória
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ScaleTransition aplica o valor da animação como escala do filho
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        // onTapDown → dedo toca a tela → anima para menor
        onTapDown: (_) => _pressController.forward(),
        // onTapUp → dedo solta → volta ao tamanho original
        onTapUp: (_) {
          _pressController.reverse();
          Navigator.pushNamed(context, widget.module.route);
        },
        // onTapCancel → dedo deslizou sem soltar → cancela
        onTapCancel: () => _pressController.reverse(),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: widget.isCenter ? 220 : 180,
      height: widget.isCenter ? 280 : 240,
      decoration: BoxDecoration(
        gradient: widget.module.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: widget.isCenter
            ? [
                BoxShadow(
                  color: widget.module.gradient.colors.first.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          _buildCardContent(),
          if (widget.module.pendingCount > 0) _buildBadge(),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.module.icon,
              color: Colors.white,
              size: 28,
            ),
          ),

          const Spacer(),

          Text(
            widget.module.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.module.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 16),

          // Botão de acesso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Abrir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${widget.module.pendingCount}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}
