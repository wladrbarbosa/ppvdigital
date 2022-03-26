import 'package:mobx/mobx.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/categoria_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_feita_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/categoria_repository.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/tarefa_feita_repository.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/tarefa_repository.dart';

class TarefasStore extends _TarefasStoreBase {
  TarefasStore(
    TarefaRepository tarefaRepo,
    TarefaFeitaRepository tarefaFeitaRepo,
    CategoriaRepository categoriaRepo,
  ) : super(
    tarefaRepo,
    tarefaFeitaRepo,
    categoriaRepo,
  );
}

abstract class _TarefasStoreBase {
  _TarefasStoreBase(
    this.tarefaRepo,
    this.tarefaFeitaRepo,
    this.categoriaRepo,
  ) {
    getListTarefas();
    getHistorico();
    getListCategorias();
  }
  final TarefaRepository tarefaRepo;
  final TarefaFeitaRepository tarefaFeitaRepo;
  final CategoriaRepository categoriaRepo;
  late final ObservableStream<List<TarefaModel>?> tarefas;
  late final ObservableStream<List<TarefaFeitaModel>?> historico;
  late final ObservableStream<List<CategoriaModel>?> categorias;
  late final void Function() getListTarefas = Action(_getListTarefas, name: 'getListTarefas');
  late void Function() clearTarefas = Action(_clearTarefas, name: 'clearTarefas');
  late final void Function() getHistorico = Action(_getHisorico, name: 'getHistorico');
  late void Function() clearHistorico = Action(_clearHistorico, name: 'clearHistorico');
  late final void Function() getListCategorias = Action(_getListCategorias, name: 'getListCategorias');
  late void Function() clearCategorias = Action(_clearCategorias, name: 'clearCategorias');

  void _getListTarefas() {
    tarefas = tarefaRepo.getTarefas().asObservable(name: 'getTarefas');
  }

  void _clearTarefas() {
    tarefaRepo.clearTarefas();
  }

  void _getHisorico() {
    historico = tarefaFeitaRepo.getHistorico().asObservable(name: 'getHistorico');
  }

  void _clearHistorico() {
    tarefaFeitaRepo.clearHistorico();
  }

  void _getListCategorias() {
    categorias = categoriaRepo.getCategorias().asObservable(name: 'getCategorias');
  }

  void _clearCategorias() {
    categoriaRepo.clearCategorias();
  }

  Future<List<CategoriaModel>?>? getListCategoriasOneShot() {
    return runInAction(() {
      return categoriaRepo.getCategoriasOneShot();
    });
  }
}
