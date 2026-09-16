import 'package:material_ui/material_ui.dart';

/// Tokens de cores do Design System do Seapruma (PPVDigital).
/// Caracterizado por ar de leveza, serenidade e tons pastéis suaves.
abstract final class AppColors {
  // --- Tons Principais Pastéis ---
  /// Menta Pastel (Primary Light) - calmaria, frescor e leveza
  static const Color primaryLight = Color(0xFF7CB9A8);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFE4F4EE);
  static const Color onPrimaryContainerLight = Color(0xFF1F4D41);

  /// Menta Pastel Dim (Primary Dark)
  static const Color primaryDark = Color(0xFF9FD3C5);
  static const Color onPrimaryDark = Color(0xFF1A372F);
  static const Color primaryContainerDark = Color(0xFF2B5347);
  static const Color onPrimaryContainerDark = Color(0xFFCEEFE6);

  /// Lavanda Pastel (Secondary Light) - sofisticação e equilíbrio
  static const Color secondaryLight = Color(0xFF9B9CD6);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFEAEBFC);
  static const Color onSecondaryContainerLight = Color(0xFF323368);

  /// Lavanda Pastel Dim (Secondary Dark)
  static const Color secondaryDark = Color(0xFFC1C2EB);
  static const Color onSecondaryDark = Color(0xFF2B2C58);
  static const Color secondaryContainerDark = Color(0xFF3E4078);
  static const Color onSecondaryContainerDark = Color(0xFFECECFD);

  /// Pêssego/Coral Pastel (Tertiary Light) - calor e amabilidade
  static const Color tertiaryLight = Color(0xFFF5B1A2);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color tertiaryContainerLight = Color(0xFFFEECE8);
  static const Color onTertiaryContainerLight = Color(0xFF6B2A1E);

  /// Pêssego/Coral Pastel Dim (Tertiary Dark)
  static const Color tertiaryDark = Color(0xFFF9CECE);
  static const Color onTertiaryDark = Color(0xFF4A2825);
  static const Color tertiaryContainerDark = Color(0xFF623B38);
  static const Color onTertiaryContainerDark = Color(0xFFFFDAD6);

  // --- Cores Semânticas Pastéis ---
  /// Sucesso Suave (Menta fresca pastel)
  static const Color pastelSuccess = Color(0xFF77CFA6);
  static const Color onPastelSuccess = Color(0xFFFFFFFF);
  static const Color pastelSuccessContainer = Color(0xFFE3F8EE);
  static const Color onPastelSuccessContainer = Color(0xFF175638);

  /// Atenção Suave (Manteiga suave pastel)
  static const Color pastelWarning = Color(0xFFF8D882);
  static const Color onPastelWarning = Color(0xFF4A3B00);
  static const Color pastelWarningContainer = Color(0xFFFDF6DE);
  static const Color onPastelWarningContainer = Color(0xFF664D00);

  /// Erro / Alerta Suave (Rosa suave pastel)
  static const Color pastelError = Color(0xFFF49E9E);
  static const Color onPastelError = Color(0xFFFFFFFF);
  static const Color pastelErrorContainer = Color(0xFFFDEAEA);
  static const Color onPastelErrorContainer = Color(0xFF6B1F1F);

  /// Informativo Suave (Céu sereno pastel)
  static const Color pastelInfo = Color(0xFF8EC7EB);
  static const Color onPastelInfo = Color(0xFFFFFFFF);
  static const Color pastelInfoContainer = Color(0xFFE5F4FD);
  static const Color onPastelInfoContainer = Color(0xFF134B6E);

  // --- Neutros & Superfícies (Modo Claro) ---
  /// Fundo arejado perolado leve (evita branco ofuscante)
  static const Color backgroundLight = Color(0xFFF9FAFC);
  /// Cartões e superfícies elevadas
  static const Color surfaceLight = Color(0xFFFFFFFF);
  /// Bordas sutis e delicadas
  static const Color borderLight = Color(0xFFE8EDF2);
  /// Divisores quase transparentes
  static const Color dividerLight = Color(0xFFF0F3F6);
  /// Texto principal com excelente contraste sem rigidez de preto puro
  static const Color textPrimaryLight = Color(0xFF2D3748);
  /// Texto secundário suave
  static const Color textSecondaryLight = Color(0xFF718096);
  /// Texto desabilitado / placeholder
  static const Color textMutedLight = Color(0xFFA0AEC0);

  // --- Neutros & Superfícies (Modo Escuro Suave) ---
  /// Fundo ardósia/carvão suave
  static const Color backgroundDark = Color(0xFF16191F);
  /// Cartões e superfícies no modo escuro
  static const Color surfaceDark = Color(0xFF20242D);
  /// Bordas suaves no escuro
  static const Color borderDark = Color(0xFF2E3543);
  /// Divisores no escuro
  static const Color dividerDark = Color(0xFF252B37);
  /// Texto principal no escuro
  static const Color textPrimaryDark = Color(0xFFF1F3F7);
  /// Texto secundário no escuro
  static const Color textSecondaryDark = Color(0xFF9AA5B6);
  /// Texto desabilitado no escuro
  static const Color textMutedDark = Color(0xFF64748B);

  // --- Cartela Ampla de 24 Cores Pastéis Personalizáveis pelo Usuário ---
  /// Cores pastéis disponíveis para personalização de hábitos, tarefas e categorias.
  /// Cada cor foi calibrada para manter alta luminosidade, conforto visual e harmonia.
  static const List<Color> customizablePastelColors = [
    Color(0xFF7CB9A8), // 1. Menta Pastel
    Color(0xFF95B8A2), // 2. Sálvia Pastel
    Color(0xFFA8D5BA), // 3. Pistache Pastel
    Color(0xFF94D2BD), // 4. Espuma do Mar (Seafoam)
    Color(0xFF80CED7), // 5. Turquesa Suave
    Color(0xFFA2D2DF), // 6. Gelo (Ice Blue)
    Color(0xFF97C8EB), // 7. Céu Sereno
    Color(0xFFA8D8EA), // 8. Azul Bebê Pastel
    Color(0xFF9FB1D9), // 9. Hortênsia (Periwinkle)
    Color(0xFFA5A6D6), // 10. Lavanda Suave
    Color(0xFFB8A7EA), // 11. Lilás Pastel
    Color(0xFFCDB4DB), // 12. Ametista Claro
    Color(0xFFD8A7CA), // 13. Ameixa Suave (Plum)
    Color(0xFFF4ACB7), // 14. Rosa Blush
    Color(0xFFFFCAD4), // 15. Algodão Doce
    Color(0xFFF7A399), // 16. Salmão Pastel
    Color(0xFFF5B1A2), // 17. Pêssego Pastel
    Color(0xFFF8B195), // 18. Coral Suave
    Color(0xFFFDC5A1), // 19. Damasco Suave
    Color(0xFFFBE29D), // 20. Manteiga Pastel
    Color(0xFFF6E7B0), // 21. Baunilha / Creme Quente
    Color(0xFFE8DAB2), // 22. Chá de Camomila
    Color(0xFFD8D4D0), // 23. Areia Suave
    Color(0xFFA0AEC0), // 24. Ardósia Pastel
  ];

  /// Converte qualquer cor (inclusive cores legadas saturadas como Colors.red)
  /// em uma variante pastel harmoniosa e iluminada.
  static Color toHarmoniousPastel(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Suaviza a saturação (máx 0.55) e eleva a luminosidade (mín 0.72)
    final pastelHsl = hsl
        .withSaturation((hsl.saturation * 0.6).clamp(0.25, 0.55))
        .withLightness((hsl.lightness * 0.5 + 0.45).clamp(0.68, 0.85));
    return pastelHsl.toColor();
  }
}
