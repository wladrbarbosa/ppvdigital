import 'package:material_ui/material_ui.dart';

/// Tokens de sombras do Design System Seapruma.
/// Focados em difusão ampla e baixíssima opacidade (4% a 8%)
/// para gerar efeito de flutuação suave sem peso visual escuro.
abstract final class AppShadows {
  /// Sombra ultra-suave para cartões em repouso e elementos sutis
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A1A202C), // ~4% de opacidade
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Sombra de cartão padrão com dispersão elegante
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D1A202C), // ~5% de opacidade
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Sombra para elementos flutuantes (FAB, diálogos, dropdowns abertos)
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x141A202C), // ~8% de opacidade
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// Sem sombra (para componentes flat com borda sutil)
  static const List<BoxShadow> none = [];
}
