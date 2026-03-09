// TIPOGRAFIA CENTRALIZADA
// -------------------------
// TextStyle define a aparência de um texto:
//   fontSize   → tamanho em pixels lógicos (dp)
//   fontWeight → espessura: w300 (leve) a w900 (extra bold)
//   letterSpacing → espaço entre letras (tracking)
//   height    → altura da linha (multiplicador do fontSize)
//
// FontWeight.w600 = SemiBold (entre Regular e Bold)
// FontWeight.w700 = Bold
// FontWeight.w800 = ExtraBold

import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // -------------------------------------------------------
  // DISPLAY — valores numéricos grandes (ex: 1.240 L)
  // -------------------------------------------------------
  static const TextStyle displayHero = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.0,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // -------------------------------------------------------
  // TÍTULO — cabeçalhos de seção e páginas
  // -------------------------------------------------------
  static const TextStyle titlePage = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.8,
  );

  static const TextStyle titleCard = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle titleSection = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // -------------------------------------------------------
  // BODY — texto de conteúdo
  // -------------------------------------------------------
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  // -------------------------------------------------------
  // LABEL — chips, badges, tags
  // -------------------------------------------------------
  static const TextStyle labelBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle labelUnit = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // -------------------------------------------------------
  // BOTÕES
  // -------------------------------------------------------
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}
