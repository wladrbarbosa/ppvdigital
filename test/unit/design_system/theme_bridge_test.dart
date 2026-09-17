import 'package:flutter/material.dart' as flutter_material;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as m_ui;
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/theme.dart';
import 'package:syncfusion_flutter_core/theme.dart' as sf_theme;

void main() {
  group('ThemeBridge Unit Tests', () {
    test('toFlutterMaterialTheme converts light m_ui.ThemeData to flutter_material.ThemeData', () {
      const materialTheme = MaterialTheme(m_ui.TextTheme());
      final uiTheme = materialTheme.light();

      final flutterTheme = ThemeBridge.toFlutterMaterialTheme(uiTheme);

      expect(flutterTheme.useMaterial3, isTrue);
      expect(flutterTheme.brightness, flutter_material.Brightness.light);
      expect(flutterTheme.colorScheme.primary, uiTheme.colorScheme.primary);
      expect(flutterTheme.colorScheme.surface, uiTheme.colorScheme.surface);
      expect(flutterTheme.colorScheme.error, uiTheme.colorScheme.error);
      expect(flutterTheme.scaffoldBackgroundColor, uiTheme.scaffoldBackgroundColor);
      expect(flutterTheme.canvasColor, uiTheme.canvasColor);
    });

    test('toFlutterMaterialTheme converts dark m_ui.ThemeData to flutter_material.ThemeData', () {
      const materialTheme = MaterialTheme(m_ui.TextTheme());
      final uiTheme = materialTheme.dark(AppThemePalette.lavanda);

      final flutterTheme = ThemeBridge.toFlutterMaterialTheme(uiTheme);

      expect(flutterTheme.useMaterial3, isTrue);
      expect(flutterTheme.brightness, flutter_material.Brightness.dark);
      expect(flutterTheme.colorScheme.primary, uiTheme.colorScheme.primary);
      expect(flutterTheme.colorScheme.surface, uiTheme.colorScheme.surface);
      expect(flutterTheme.colorScheme.error, uiTheme.colorScheme.error);
    });

    testWidgets('createSfCalendarTheme generates SfCalendarThemeData matching context theme in light mode', (tester) async {
      const materialTheme = MaterialTheme(m_ui.TextTheme());
      late sf_theme.SfCalendarThemeData calendarTheme;

      await tester.pumpWidget(
        m_ui.MaterialApp(
          theme: materialTheme.light(AppThemePalette.ceuSereno),
          home: m_ui.Builder(
            builder: (context) {
              calendarTheme = ThemeBridge.createSfCalendarTheme(context);
              return const m_ui.SizedBox();
            },
          ),
        ),
      );

      expect(calendarTheme.backgroundColor, AppColors.backgroundLight);
      expect(calendarTheme.headerBackgroundColor, AppColors.surfaceLight);
      expect(calendarTheme.todayHighlightColor, AppThemePalette.ceuSereno.primaryLight);
      expect(calendarTheme.selectionBorderColor, AppThemePalette.ceuSereno.primaryLight);
      expect(calendarTheme.cellBorderColor, AppColors.borderLight);
      expect(calendarTheme.headerTextStyle?.color, AppColors.textPrimaryLight);
      expect(calendarTheme.viewHeaderDayTextStyle?.color, AppColors.textSecondaryLight);
    });

    testWidgets('createSfCalendarTheme generates SfCalendarThemeData matching context theme in dark mode', (tester) async {
      const materialTheme = MaterialTheme(m_ui.TextTheme());
      late sf_theme.SfCalendarThemeData calendarTheme;

      await tester.pumpWidget(
        m_ui.MaterialApp(
          theme: materialTheme.dark(AppThemePalette.pessego),
          home: m_ui.Builder(
            builder: (context) {
              calendarTheme = ThemeBridge.createSfCalendarTheme(context);
              return const m_ui.SizedBox();
            },
          ),
        ),
      );

      expect(calendarTheme.backgroundColor, AppColors.backgroundDark);
      expect(calendarTheme.headerBackgroundColor, AppColors.surfaceDark);
      expect(calendarTheme.todayHighlightColor, AppThemePalette.pessego.primaryDark);
      expect(calendarTheme.selectionBorderColor, AppThemePalette.pessego.primaryDark);
      expect(calendarTheme.cellBorderColor, AppColors.borderDark);
      expect(calendarTheme.headerTextStyle?.color, AppColors.textPrimaryDark);
      expect(calendarTheme.viewHeaderDayTextStyle?.color, AppColors.textSecondaryDark);
    });
  });
}
