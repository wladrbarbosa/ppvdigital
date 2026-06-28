import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/calendario_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/categorias_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_layout.dart';
import 'package:ppvdigital/app/login/login_controller.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${(a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
}

class Core {
  factory Core() {
    return instance;
  }
  Core._internal();

  static final Core instance = Core._internal();
  static Client client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('671f6df50033227ea6d6');

  static LoginController loginController = LoginController();
  static TarefasHabitosController tarefasHabitosController =
      TarefasHabitosController();
  static HistoricoController historicoController = HistoricoController();
  static CalendarioController calendarioController = CalendarioController();
  static CategoriasController categoriasController = CategoriasController();
  static FinancasController financasController = FinancasController();
  static GlobalKey<TarefasPageState> globalKey = GlobalKey<TarefasPageState>();
}
