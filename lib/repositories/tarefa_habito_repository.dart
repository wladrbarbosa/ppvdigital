import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

abstract class TarefaHabitoRepository {
  Future<List<TarefaHabitoModel>> getTarefasEHabitos({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<Set<String>> getActiveTarefaHabitoIds({
    required String usuarioId,
  });

  Future<List<HistoricoItemModel>> getHistorico({
    required String usuarioId,
    bool forceLocal = false,
    DateTime? lastSyncedAt,
  });

  Future<Set<String>> getActiveHistoricoIds({
    required String usuarioId,
  });

  Future<void> recordHistorico({
    String? id,
    required String foundId,
    required String usuarioId,
  });

  Future<void> updateConcluida({
    required String documentId,
    required bool concluida,
  });

  Future<bool> createTarefaHabito({
    String? id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
    int? duration,
    bool arquivado = false,
    required String usuarioId,
  });

  Future<bool> updateTarefaHabito({
    required String id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    required List<String> allExistingQtdRowIds,
    DateTime? agendamento,
    int? duration,
    bool? arquivado,
    required String usuarioId,
  });

  Future<bool> deleteTarefaHabito({
    required String id,
    required List<String> qtdRowIds,
  });

  Future<bool> deleteHistoricoItem({required String id});

  Stream<List<TarefaHabitoModel>> watchTarefasEHabitos({
    required String usuarioId,
  });

  Stream<List<HistoricoItemModel>> watchHistorico({
    required String usuarioId,
  });

  Future<void> updateCategoryInMetas(CategoriasTarefasHabitosModel updatedCategory);
  Future<void> removeCategoryFromMetas(String categoryId);
}
