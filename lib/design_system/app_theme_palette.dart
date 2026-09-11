import 'package:flutter/material.dart';

/// Enumeração das 10 paletas de cores pastéis oficiais do Design System Seapruma.
enum AppThemePalette {
  menta(
    id: 'menta',
    label: 'Menta Pastel',
    primaryLight: Color(0xFF7CB9A8),
    primaryDark: Color(0xFF9FD3C5),
    primaryContainerLight: Color(0xFFE4F4EE),
    primaryContainerDark: Color(0xFF2B5347),
    onPrimaryContainerLight: Color(0xFF1F4D41),
    onPrimaryContainerDark: Color(0xFFCEEFE6),
  ),
  lavanda(
    id: 'lavanda',
    label: 'Lavanda Suave',
    primaryLight: Color(0xFFA5A6D6),
    primaryDark: Color(0xFFC1C2EB),
    primaryContainerLight: Color(0xFFEAEBFC),
    primaryContainerDark: Color(0xFF3E4078),
    onPrimaryContainerLight: Color(0xFF323368),
    onPrimaryContainerDark: Color(0xFFECECFD),
  ),
  pessego(
    id: 'pessego',
    label: 'Pêssego Pastel',
    primaryLight: Color(0xFFF5B1A2),
    primaryDark: Color(0xFFF9CECE),
    primaryContainerLight: Color(0xFFFEECE8),
    primaryContainerDark: Color(0xFF623B38),
    onPrimaryContainerLight: Color(0xFF6B2A1E),
    onPrimaryContainerDark: Color(0xFFFFDAD6),
  ),
  ceuSereno(
    id: 'ceuSereno',
    label: 'Céu Sereno',
    primaryLight: Color(0xFF97C8EB),
    primaryDark: Color(0xFFB5DBF2),
    primaryContainerLight: Color(0xFFE5F4FD),
    primaryContainerDark: Color(0xFF2A495E),
    onPrimaryContainerLight: Color(0xFF134B6E),
    onPrimaryContainerDark: Color(0xFFD3EDFC),
  ),
  salvia(
    id: 'salvia',
    label: 'Sálvia Pastel',
    primaryLight: Color(0xFF95B8A2),
    primaryDark: Color(0xFFADC7B6),
    primaryContainerLight: Color(0xFFE9F3EC),
    primaryContainerDark: Color(0xFF344F3F),
    onPrimaryContainerLight: Color(0xFF254B34),
    onPrimaryContainerDark: Color(0xFFD6EBDE),
  ),
  rosaBlush(
    id: 'rosaBlush',
    label: 'Rosa Blush',
    primaryLight: Color(0xFFF4ACB7),
    primaryDark: Color(0xFFFAC6CE),
    primaryContainerLight: Color(0xFFFDECEE),
    primaryContainerDark: Color(0xFF5D363C),
    onPrimaryContainerLight: Color(0xFF69242E),
    onPrimaryContainerDark: Color(0xFFFFD9DF),
  ),
  turquesa(
    id: 'turquesa',
    label: 'Turquesa Suave',
    primaryLight: Color(0xFF80CED7),
    primaryDark: Color(0xFF9FDDE4),
    primaryContainerLight: Color(0xFFE5F8FA),
    primaryContainerDark: Color(0xFF234F55),
    onPrimaryContainerLight: Color(0xFF134D54),
    onPrimaryContainerDark: Color(0xFFCEF4F7),
  ),
  ametista(
    id: 'ametista',
    label: 'Ametista Claro',
    primaryLight: Color(0xFFCDB4DB),
    primaryDark: Color(0xFFDDC7E7),
    primaryContainerLight: Color(0xFFF6EEFA),
    primaryContainerDark: Color(0xFF4C3857),
    onPrimaryContainerLight: Color(0xFF4F2C61),
    onPrimaryContainerDark: Color(0xFFF2E0F9),
  ),
  baunilha(
    id: 'baunilha',
    label: 'Baunilha Suave',
    primaryLight: Color(0xFFF6E7B0),
    primaryDark: Color(0xFFF9ECC7),
    primaryContainerLight: Color(0xFFFDF9EC),
    primaryContainerDark: Color(0xFF594F2B),
    onPrimaryContainerLight: Color(0xFF5C4E13),
    onPrimaryContainerDark: Color(0xFFFCF4DC),
  ),
  areia(
    id: 'areia',
    label: 'Areia Suave',
    primaryLight: Color(0xFFD8D4D0),
    primaryDark: Color(0xFFE5E2DF),
    primaryContainerLight: Color(0xFFF7F6F5),
    primaryContainerDark: Color(0xFF4A4744),
    onPrimaryContainerLight: Color(0xFF474441),
    onPrimaryContainerDark: Color(0xFFF0EEEB),
  );

  const AppThemePalette({
    required this.id,
    required this.label,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryContainerLight,
    required this.primaryContainerDark,
    required this.onPrimaryContainerLight,
    required this.onPrimaryContainerDark,
  });

  final String id;
  final String label;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryContainerLight;
  final Color primaryContainerDark;
  final Color onPrimaryContainerLight;
  final Color onPrimaryContainerDark;

  Color get onPrimaryLight => Colors.white;
  Color get onPrimaryDark => const Color(0xFF1A1F26);

  static AppThemePalette fromString(String? value) {
    if (value == null) return AppThemePalette.menta;
    final normalized = value.trim().toLowerCase();
    for (final palette in AppThemePalette.values) {
      if (palette.id.toLowerCase() == normalized ||
          palette.name.toLowerCase() == normalized) {
        return palette;
      }
    }
    return AppThemePalette.menta;
  }
}
