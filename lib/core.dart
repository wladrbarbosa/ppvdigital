import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/calendario_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/categorias_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/tarefas_habitos_controller.dart';
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

  // Appwrite Connection parameters
  static const String endpoint = 'https://appwrite.wladapps.com/v1';
  static const String projectId = '6a46a08b0009901f8788';

  // Appwrite Database parameters
  static const String databaseId = '671f6e1600022832cba5';

  // Appwrite Collection / Table IDs
  static const String tableTransacoes = '671f7a6f000cb3ab17b9';
  static const String tableContas = '671f7aa70014dda7507c';
  static const String tableTarefasEHabitos = '671f864f0023d1c27de8';
  static const String tableCategoriasTarefasHabitos = '671f8803003d7d827ea8';
  static const String tableHistoricoTarefasHabitos = '6741f10d000d985e4af9';
  static const String tableTarefasHabitosQtds = '674cfd5e001a6582741e';
  static const String tableCategoriasTransacoes = 'categorias_transacoes';
  static const String tableTransacaoRecorrencias = 'transacao_recorrencia';
  static const String tableDivisaoTransacoes = 'divisao_transacoes';
  static const String tableContatos = 'contatos';

  static Client client = Client().setEndpoint(endpoint).setProject(projectId);

  static LoginController loginController = LoginController();
  static TarefasHabitosController tarefasHabitosController =
      TarefasHabitosController();
  static HistoricoController historicoController = HistoricoController();
  static CalendarioController calendarioController = CalendarioController();
  static CategoriasController categoriasController = CategoriasController();
  static FinancasController financasController = FinancasController();
  static GlobalKey<TarefasPageState> globalKey = GlobalKey<TarefasPageState>();
  static const String appVersion = 'b0.13.0+1';
}
