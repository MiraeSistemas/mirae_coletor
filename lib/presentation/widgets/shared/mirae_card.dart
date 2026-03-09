// WIDGET REUTILIZÁVEL: MiraeCard
// --------------------------------
// Em Flutter, extrair widgets repetidos em classes próprias é
// uma boa prática (evita duplicação e facilita manutenção).
//
// StatelessWidget → widget sem estado interno.
// Recebe dados pelos parâmetros e renderiza sempre igual
// para os mesmos dados.
//
// PARÂMETROS COM VALOR PADRÃO:
// Widget({this.padding = const EdgeInsets.all(20)})
// → se não informado, usa EdgeInsets.all(20)
//
// PARÂMETROS OBRIGATÓRIOS:
// Widget({required this.child})
// → deve sempre ser informado ao usar o widget

import 'package:flutter/material.dart';
import 'package:mirae_coletor/core/theme/app_colors.dart';

// -------------------------------------------------------
// MIRAE CARD — container padrão do app
// -------------------------------------------------------
class MiraeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap; // VoidCallback = função sem parâmetros e sem retorno

  const MiraeCard({
    super.key,        // super.key repassa a key para o StatelessWidget pai
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Container com decoração customizada
    final container = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // gradient tem prioridade sobre color
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.surface) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Se tem gradiente, borda transparente; senão, borda sutil
          color: gradient != null
              ? Colors.transparent
              : AppColors.border,
          width: 1,
        ),
      ),
      child: child,
    );

    // Se tem callback de toque, envolve com InkWell
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: container,
      );
    }

    return container;
  }
}

// -------------------------------------------------------
// STATUS BADGE — IN STOCK / LOW STOCK / CRITICAL
// -------------------------------------------------------
enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.success,
  });

  @override
  Widget build(BuildContext context) {
    // Map para associar tipo → cores
    // Uso do operador '!' após o acesso no Map porque sabemos
    // que a chave sempre existirá (cobrimos todos os enum values)
    final colors = {
      BadgeType.success: (AppColors.primary, AppColors.primarySubtle),
      BadgeType.warning: (AppColors.warning, AppColors.warningSubtle),
      BadgeType.danger:  (AppColors.danger,  AppColors.dangerSubtle),
      BadgeType.info:    (AppColors.blue,     AppColors.blueSubtle),
      BadgeType.neutral: (AppColors.textSecondary, AppColors.border),
    };

    // Desestruturação de Record (Dart 3+):
    // (textColor, bgColor) = tuple com dois valores
    final (textColor, bgColor) = colors[type]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// SECTION HEADER — título de seção com ícone opcional
// -------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing; // widget opcional à direita (ex: botão "Ver mais")

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        // Spacer() expande e empurra o trailing para a direita
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// -------------------------------------------------------
// MIRAE BUTTON — botão primário padrão
// -------------------------------------------------------
class MiraeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  const MiraeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Largura máxima disponível
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        // Se isLoading, desabilita o botão (onPressed = null desabilita)
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            // CircularProgressIndicator dentro do botão durante loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// -------------------------------------------------------
// HISTORY ITEM — linha de histórico padrão
// -------------------------------------------------------
class HistoryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const HistoryItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.icon = Icons.history_rounded,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ícone em container circular
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          // Título e subtítulo expandem o espaço disponível
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    )),
              ],
            ),
          ),
          // Valor à direita
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
