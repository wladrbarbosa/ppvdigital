import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/theme.dart';
import 'package:ppvdigital/util.dart';

void main() {
  group('Design System - Theme & Typography Integration', () {
    test('MaterialTheme.lightScheme reflete a paleta pastel e fundos arejados', () {
      final scheme = MaterialTheme.lightScheme();
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, AppColors.primaryLight);
      expect(scheme.secondary, AppColors.secondaryLight);
      expect(scheme.tertiary, AppColors.tertiaryLight);
      expect(scheme.surface, AppColors.backgroundLight);
      expect(scheme.surfaceContainerLowest, AppColors.surfaceLight);
    });

    test('MaterialTheme.darkScheme reflete a paleta pastel escura com superfícies suaves', () {
      final scheme = MaterialTheme.darkScheme();
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, AppColors.primaryDark);
      expect(scheme.secondary, AppColors.secondaryDark);
      expect(scheme.tertiary, AppColors.tertiaryDark);
      expect(scheme.surface, AppColors.backgroundDark);
      expect(scheme.surfaceContainerLowest, AppColors.surfaceDark);
    });

    test('MaterialTheme.theme configura componentes globais com leveza e curvas suaves', () {
      const materialTheme = MaterialTheme(TextTheme());
      final lightTheme = materialTheme.light();

      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.backgroundLight);

      // CardTheme deve ter borda sutil e curvatura suave
      final cardTheme = lightTheme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      final cardShape = cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, AppRadius.roundedLg);

      // DialogTheme deve ter cantos generosos
      final dialogTheme = lightTheme.dialogTheme;
      expect(dialogTheme.shape, isA<RoundedRectangleBorder>());
      final dialogShape = dialogTheme.shape as RoundedRectangleBorder;
      expect(dialogShape.borderRadius, AppRadius.roundedXl);
    });

    testWidgets('createTextTheme aplica Plus Jakarta Sans com fallback seguro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final theme = createTextTheme(context, 'Plus Jakarta Sans', 'Plus Jakarta Sans');
              expect(theme, isNotNull);
              expect(theme.bodyLarge, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
