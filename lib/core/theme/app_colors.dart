// SISTEMA DE CORES CENTRALIZADO
// --------------------------------
// Em Flutter, cores são constantes do tipo Color.
// Color(0xFF______) → 0xFF = opacidade 100%, seguido do hex RGB
// Color(0x80______) → 0x80 = opacidade ~50%
//
// Centralizar as cores aqui evita "magic numbers" espalhados
// pelo código. Se precisar ajustar uma cor, muda em um lugar só.
//
// CONCEITO DART: abstract class com static const
// → 'abstract' impede instanciação (não faz sentido criar AppColors())
// → 'static const' = pertence à classe, não à instância, e é imutável
//    Uso: AppColors.background (sem new AppColors())

import 'package:flutter/material.dart';

abstract class AppColors {
  // -------------------------------------------------------
  // FUNDOS
  // -------------------------------------------------------
  /// Fundo principal do app — azul marinho escuro
  static const Color background = Color(0xFF0A1628);

  /// Fundo dos cards e painéis secundários
  static const Color surface = Color(0xFF142035);

  /// Fundo de elementos elevados (modais, dropdowns)
  static const Color surfaceElevated = Color(0xFF1C2E45);

  /// Borda sutil entre elementos
  static const Color border = Color(0xFF243654);

  // -------------------------------------------------------
  // CORES PRIMÁRIAS
  // -------------------------------------------------------
  /// Verde Mirae — ações principais, sucesso, destaque
  static const Color primary = Color(0xFF00C853);

  /// Verde mais escuro — hover / pressed state
  static const Color primaryDark = Color(0xFF00A040);

  /// Verde com transparência — backgrounds de badges/chips
  static const Color primarySubtle = Color(0x1A00C853);

  // -------------------------------------------------------
  // CORES SECUNDÁRIAS
  // -------------------------------------------------------
  /// Azul — pluviômetro, informação, links
  static const Color blue = Color(0xFF1976D2);
  static const Color blueLight = Color(0xFF42A5F5);
  static const Color blueSubtle = Color(0x1A1976D2);

  /// Laranja/Amarelo — nível de tanque, alertas de atenção
  static const Color warning = Color(0xFFFFA000);
  static const Color warningSubtle = Color(0x1AFFA000);

  /// Vermelho — crítico, erro, exclusão
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerSubtle = Color(0x1AD32F2F);

  // -------------------------------------------------------
  // TEXTO
  // -------------------------------------------------------
  /// Texto principal — branco
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto secundário — branco com 60% de opacidade
  static const Color textSecondary = Color(0x99FFFFFF);

  /// Texto terciário / placeholder — branco com 35%
  static const Color textTertiary = Color(0x59FFFFFF);

  // -------------------------------------------------------
  // GRADIENTES
  // Os módulos do carrossel têm gradientes únicos
  // -------------------------------------------------------
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientBlue = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSync = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientStock = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientFuel = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFBF360C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
