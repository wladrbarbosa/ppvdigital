import 'dart:async';

import 'package:ppvdigital/app/capacitacao/tarefas_habitos/historico_controller.dart';

class CalendarioController extends HistoricoController {
  CalendarioController() : super();

  static Future<void>? historicoFuture;

  @override
  void reset() {
    historicoFuture = null;
    super.reset();
  }
}
