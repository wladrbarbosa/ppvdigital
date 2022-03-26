import 'package:flutter_modular/flutter_modular.dart';
import 'package:ppvdigital/app/modules/capacitacao/capacitacao_module.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/tarefas_module.dart';
import 'package:ppvdigital/app/modules/home/home_module.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRoute> routes = [
    ModuleRoute(Modular.initialRoute, module: HomeModule()),
    ModuleRoute('/capacitacao-tecnica', module: CapacitacaoModule()),
    ModuleRoute('/capacitacao-tecnica/tarefas', module: TarefasModule()),
  ];
}
