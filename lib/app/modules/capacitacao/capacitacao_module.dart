import 'package:flutter_modular/flutter_modular.dart';
import 'package:ppvdigital/app/modules/capacitacao/capacitacao_page.dart';
import 'package:ppvdigital/app/modules/capacitacao/capacitacao_store.dart';
 
class CapacitacaoModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => CapacitacaoStore()),
  ];

 @override
 final List<ModularRoute> routes = [
   ChildRoute('/capacitacao-tecnica', child: (_, args) => const CapacitacaoPage()),
 ];
}
