import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/categoria_repository.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/tarefa_feita_repository.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/tarefa_repository.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/tarefas_page.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/tarefas_store.dart';
 
class TarefasModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => TarefasStore(i.get<TarefaRepository>(), i.get<TarefaFeitaRepository>(), i.get<CategoriaRepository>())),
    Bind.lazySingleton((i) => TarefaRepository(FirebaseFirestore.instance)),
    Bind.lazySingleton((i) => TarefaFeitaRepository(FirebaseFirestore.instance)),
    Bind.lazySingleton((i) => CategoriaRepository(FirebaseFirestore.instance)),
  ];

 @override
 final List<ModularRoute> routes = [
   ChildRoute('/capacitacao-tecnica/tarefas', child: (_, args) => const TarefasPage()),
 ];
}
