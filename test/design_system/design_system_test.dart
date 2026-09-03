import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/design_system/design_system.dart';

void main() {
  group('Design System - Tokens', () {
    test('AppColors possui paleta pastel primária, secundária e terciária', () {
      expect(AppColors.primaryLight, const Color(0xFF7CB9A8));
      expect(AppColors.primaryDark, const Color(0xFF9FD3C5));
      expect(AppColors.secondaryLight, const Color(0xFF9B9CD6));
      expect(AppColors.secondaryDark, const Color(0xFFC1C2EB));
      expect(AppColors.tertiaryLight, const Color(0xFFF5B1A2));
      expect(AppColors.tertiaryDark, const Color(0xFFF9CECE));
    });

    test('AppColors possui cores semânticas suaves com containers correspondentes', () {
      expect(AppColors.pastelSuccess, const Color(0xFF77CFA6));
      expect(AppColors.pastelSuccessContainer, const Color(0xFFE3F8EE));
      expect(AppColors.pastelWarning, const Color(0xFFF8D882));
      expect(AppColors.pastelWarningContainer, const Color(0xFFFDF6DE));
      expect(AppColors.pastelError, const Color(0xFFF49E9E));
      expect(AppColors.pastelErrorContainer, const Color(0xFFFDEAEA));
      expect(AppColors.pastelInfo, const Color(0xFF8EC7EB));
      expect(AppColors.pastelInfoContainer, const Color(0xFFE5F4FD));
    });

    test('AppColors possui superfícies e neutros leves para modo claro e escuro', () {
      expect(AppColors.backgroundLight, const Color(0xFFF9FAFC));
      expect(AppColors.surfaceLight, const Color(0xFFFFFFFF));
      expect(AppColors.borderLight, const Color(0xFFE8EDF2));
      expect(AppColors.textPrimaryLight, const Color(0xFF2D3748));
      expect(AppColors.textSecondaryLight, const Color(0xFF718096));

      expect(AppColors.backgroundDark, const Color(0xFF16191F));
      expect(AppColors.surfaceDark, const Color(0xFF20242D));
      expect(AppColors.borderDark, const Color(0xFF2E3543));
      expect(AppColors.textPrimaryDark, const Color(0xFFF1F3F7));
      expect(AppColors.textSecondaryDark, const Color(0xFF9AA5B6));
    });

    test('AppColors.customizablePastelColors contém exatamente 24 opções únicas e elegantes', () {
      expect(AppColors.customizablePastelColors.length, equals(24));
      final uniqueColors = AppColors.customizablePastelColors.map((c) => c.toARGB32()).toSet();
      expect(uniqueColors.length, equals(24));
    });

    test('AppColors.toHarmoniousPastel suaviza qualquer cor garantindo ar de leveza', () {
      const harshRed = Colors.red;
      final softenedRed = AppColors.toHarmoniousPastel(harshRed);
      expect(softenedRed, isNotNull);
      // Deve ter luminosidade mais alta e ser suave
      expect(softenedRed.computeLuminance(), greaterThan(0.3));

      // Se já for uma cor pastel da lista, retorna com segurança
      final pastel = AppColors.customizablePastelColors.first;
      expect(AppColors.toHarmoniousPastel(pastel), isNotNull);
    });

    test('AppSpacing define grid escalonado coerente', () {
      expect(AppSpacing.xxs, 2.0);
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
    });

    test('AppRadius define raios e BorderRadii adequados', () {
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 24.0);
      expect(AppRadius.full, 999.0);

      expect(AppRadius.roundedSm, BorderRadius.circular(8.0));
      expect(AppRadius.roundedMd, BorderRadius.circular(12.0));
      expect(AppRadius.roundedLg, BorderRadius.circular(16.0));
      expect(AppRadius.roundedFull, BorderRadius.circular(999.0));
    });

    test('AppShadows possui sombras arejadas de baixa opacidade', () {
      expect(AppShadows.soft.length, 1);
      expect(AppShadows.card.length, 1);
      expect(AppShadows.floating.length, 1);
      expect(AppShadows.soft.first.blurRadius, equals(10));
    });

    test('AppDecorations cria decorações de cards e badges com leveza', () {
      final cardDeco = AppDecorations.card();
      expect(cardDeco.color, equals(AppColors.surfaceLight));
      expect(cardDeco.borderRadius, equals(AppRadius.roundedLg));
      expect(cardDeco.border, isNotNull);

      final darkCardDeco = AppDecorations.card(isDark: true);
      expect(darkCardDeco.color, equals(AppColors.surfaceDark));

      final badgeDeco = AppDecorations.badge(
        backgroundColor: AppColors.pastelSuccessContainer,
        borderColor: AppColors.pastelSuccess,
      );
      expect(badgeDeco.color, equals(AppColors.pastelSuccessContainer));
      expect(badgeDeco.borderRadius, equals(AppRadius.roundedFull));
    });
  });
}
