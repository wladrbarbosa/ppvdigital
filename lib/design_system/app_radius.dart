import 'package:flutter/material.dart';

/// Tokens de curvatura e cantos arredondados do Design System Seapruma.
/// Curvas generosas transmitem suavidade, calor e modernidade.
abstract final class AppRadius {
  /// 4.0 - Curvatura mínima (tags, indicadores muito pequenos)
  static const double xs = 4.0;

  /// 8.0 - Curvatura pequena (inputs compactos, tooltips)
  static const double sm = 8.0;

  /// 12.0 - Curvatura média (botões, campos de texto, dropdowns)
  static const double md = 12.0;

  /// 16.0 - Curvatura padrão para cartões (cards de hábitos, tarefas, módulos)
  static const double lg = 16.0;

  /// 24.0 - Curvatura grande (diálogos, bottom sheets, containers destacados)
  static const double xl = 24.0;

  /// 999.0 - Formato pílula / circular completo (chips, badges, avatares)
  static const double full = 999.0;

  // --- Helpers de BorderRadius prontos para uso ---
  static final BorderRadius roundedXs = BorderRadius.circular(xs);
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}
