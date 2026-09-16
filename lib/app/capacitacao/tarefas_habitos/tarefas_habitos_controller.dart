import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:material_ui/material_ui.dart' hide Row;
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/repositories/tarefa_habito_repository.dart';

extension TarefasHabitosTransformList on List<dynamic>? {
  List<TarefaHabitoQtdModel> toTarefaHabitoQtdModelList([
    List<HistoricoItemModel>? tarefaHabitoHistoricoList,
  ]) {
    return this?.map<TarefaHabitoQtdModel>((e2) {
          final Map<String, dynamic> e2Map = e2 is Map
              ? Map<String, dynamic>.from(e2)
              : <String, dynamic>{};
          List<HistoricoItemModel> withPeriodFilter = [];
          final rawCreatedAt =
              e2Map[r'$createdAt'] ??
              e2Map['createdAt'] ??
              e2Map['dataCriacao'];
          DateTime parsedBeginning = DateTime.now();
          if (rawCreatedAt is String) {
            parsedBeginning =
                DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now();
          } else if (rawCreatedAt is int) {
            parsedBeginning = DateTime.fromMillisecondsSinceEpoch(
              rawCreatedAt,
            ).toLocal();
          }
          final DateTime beginning = DateTime(
            parsedBeginning.year,
            parsedBeginning.month,
            parsedBeginning.day,
          );
          final String reiniciaEmTipo =
              (e2Map['reiniciaEmTipo'] as String?) ?? 'dias';
          final int reiniciaEmQtd = (e2Map['reiniciaEmQtd'] as num?)?.toInt() ?? 1;

          if (tarefaHabitoHistoricoList != null &&
              tarefaHabitoHistoricoList.isNotEmpty) {
            final DateTime startPeriod =
                TarefaHabitoQtdModel.calculateStartPeriod(
                  createdAt: beginning,
                  reiniciaEmTipo: reiniciaEmTipo,
                  reiniciaEmQtd: reiniciaEmQtd,
                );

            withPeriodFilter = tarefaHabitoHistoricoList.where((el) {
              final DateTime elDate = DateTime(
                el.createdAt.year,
                el.createdAt.month,
                el.createdAt.day,
              );
              return elDate.isAtSameMomentAs(startPeriod) ||
                  elDate.isAfter(startPeriod);
            }).toList();
          }

          final String? collectionId = e2Map[r'$collectionId'] as String?;
          if (collectionId != null) {
            TarefasHabitosController.tarefasHabitosQtdCollectionId =
                collectionId;
          }

          final Map<String, dynamic>? rawCategoryMap =
              e2Map['categoriasTarefasHabitos'] is Map
                  ? Map<String, dynamic>.from(
                      e2Map['categoriasTarefasHabitos'] as Map,
                    )
                  : null;

          final num valor = (e2Map['valor'] as num?) ?? 1.0;
          num calculatedVezes = 0;
          if (valor < 0) {
            final DateTime now = DateTime.now();
            final DateTime today = DateTime(now.year, now.month, now.day);
            final DateTime lastDate;
            if (tarefaHabitoHistoricoList != null &&
                tarefaHabitoHistoricoList.isNotEmpty) {
              final sortedHist = List<HistoricoItemModel>.from(
                tarefaHabitoHistoricoList,
              )..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              lastDate = sortedHist.last.createdAt.toLocal();
            } else {
              lastDate = beginning;
            }
            final DateTime lastDay =
                DateTime(lastDate.year, lastDate.month, lastDate.day);
            calculatedVezes =
                today.difference(lastDay).inDays.clamp(0, 999999);
          } else {
            calculatedVezes =
                withPeriodFilter.length * valor;
          }

          return TarefaHabitoQtdModel(
            id: (e2Map[r'$id'] ?? e2Map['id'] ?? '') as String,
            usuario: (e2Map['usuario'] as String?) ?? '',
            metaVezes: (e2Map['metaVezes'] as num?)?.toInt() ?? 1,
            categoriasTarefasHabitos:
                TarefasHabitosTransformDocumentList
                    .toCategoriasTarefasHabitosModelList(rawCategoryMap),
            valor: valor,
            reiniciaEmQtd: reiniciaEmQtd,
            reiniciaEmTipo: reiniciaEmTipo,
            vezesPraticado: calculatedVezes,
            createdAt: beginning,
          );
        }).toList() ??
        [];
  }
}

extension TarefasHabitosTransformDocumentList on List<Row> {
  Future<List<TarefaHabitoModel>> toTarefaHabitoModelList(
    Databases databases,
    String usuarioId,
  ) async {
    final List<TarefaHabitoModel> temp = [];

    final List<HistoricoItemModel> allHistoryItems =
        await Core.tarefaHabitoRepository.getHistorico(
          usuarioId: usuarioId,
          forceLocal: true,
        );

    for (final e1 in this) {
      final List<HistoricoItemModel> tarefaHabitoQtdList = allHistoryItems
          .where((item) => item.tarefasEHabitos.id == e1.$id)
          .toList();

      final rawConcluida = e1.data['concluida'];
      final bool isConcluida = rawConcluida is bool
          ? rawConcluida
          : (rawConcluida == 1 || rawConcluida == 'true' || rawConcluida == '1');

      final rawArquivado = e1.data['arquivado'];
      final bool isArquivado = rawArquivado is bool
          ? rawArquivado
          : (rawArquivado == 1 || rawArquivado == 'true' || rawArquivado == '1');

      temp.add(
        TarefaHabitoModel(
          id: e1.$id,
          nome: (e1.data['nome'] as String?) ?? '',
          usuario: (e1.data['usuario'] as String?) ?? '',
          tipo: (e1.data['tipo'] as String?) ?? '',
          agendamento: DateTime.tryParse(
            (e1.data['agendamento'] as String?) ?? '',
          ),
          concluida: isConcluida,
          arquivado: isArquivado,
          tarefasHabitosQtd: (e1.data['tarefasHabitosQtds'] as List<dynamic>?)
              .toTarefaHabitoQtdModelList(tarefaHabitoQtdList),
          duration: e1.data['duration'] is num
              ? (e1.data['duration'] as num).toInt()
              : null,
        ),
      );
    }

    return temp;
  }

  static CategoriasTarefasHabitosModel? toCategoriasTarefasHabitosModelList(
    Map<String, dynamic>? map,
  ) {
    return map != null
        ? CategoriasTarefasHabitosModel(
            id: (map[r'$id'] ?? map['id'] ?? '') as String,
            nome: (map['nome'] ?? '') as String,
            cor: HexColor.fromHex((map['cor'] ?? '#ffffff') as String),
            usuario: (map['usuario'] ?? '') as String,
          )
        : null;
  }
}

class TarefasHabitosController {
  TarefasHabitosController(this.repository);

  final TarefaHabitoRepository repository;

  static String tarefasHabitosQtdCollectionId = '';

  static Future<dynamic>? tarefasHabitosFuture;

  final mobx.Observable<Color> _habitColor = mobx.Observable<Color>(
    Colors.deepPurpleAccent,
    name: 'habitColor',
  );
  mobx.Observable<Color> get habitColor => _habitColor;

  final mobx.Observable<Color> _taskColor = mobx.Observable<Color>(
    Colors.teal,
    name: 'taskColor',
  );
  mobx.Observable<Color> get taskColor => _taskColor;

  static const String _habitColorKey = 'habit_custom_color';
  static const String _taskColorKey = 'task_custom_color';

  Future<void> loadCustomColors() async {
    try {
      final habitColorStr = await Core.database.getSetting(_habitColorKey);
      if (habitColorStr != null) {
        final val = int.tryParse(habitColorStr);
        if (val != null) {
          mobx.runInAction(() {
            _habitColor.value = Color(val);
          });
        }
      }

      final taskColorStr = await Core.database.getSetting(_taskColorKey);
      if (taskColorStr != null) {
        final val = int.tryParse(taskColorStr);
        if (val != null) {
          mobx.runInAction(() {
            _taskColor.value = Color(val);
          });
        }
      }
    } catch (e) {
      log('Could not load configured colors: $e');
    }
  }

  Future<void> setHabitColor(Color color) async {
    mobx.runInAction(() {
      _habitColor.value = color;
    });
    try {
      await Core.database.setSetting(_habitColorKey, color.toARGB32().toString());
    } catch (e) {
      log('Could not save habit color: $e');
    }
  }

  Future<void> setTaskColor(Color color) async {
    mobx.runInAction(() {
      _taskColor.value = color;
    });
    try {
      await Core.database.setSetting(_taskColorKey, color.toARGB32().toString());
    } catch (e) {
      log('Could not save task color: $e');
    }
  }

  final mobx.ObservableList<TarefaHabitoModel> _tarefasHabitosList =
      mobx.ObservableList<TarefaHabitoModel>();

  List<TarefaHabitoModel> get tarefasHabitosList => _tarefasHabitosList;

  final mobx.Observable<bool> _isSyncing = mobx.Observable<bool>(
    false,
    name: 'isSyncing',
  );
  bool get isSyncing => _isSyncing.value;

  DateTime? _lastSyncTime;
  StreamSubscription<List<TarefaHabitoModel>>? _tarefasHabitosSub;

  Future<List<TarefaHabitoModel>> loadDocuments({bool forceSync = false}) async {
    final now = DateTime.now();
    if (Core.loginController.currentUser == null) {
      await Core.loginController.loadUser();
    }
    final String user = Core.loginController.currentUser?.$id ?? '';

    _setupReactiveStreams(user);

    final localFuture = repository.getTarefasEHabitos(
      usuarioId: user,
      forceLocal: true,
    );

    tarefasHabitosFuture = localFuture;

    final localData = await localFuture;
    mobx.runInAction(() {
      _tarefasHabitosList.clear();
      _tarefasHabitosList.addAll(localData);
    });

    if (!forceSync &&
        _lastSyncTime != null &&
        now.difference(_lastSyncTime!) < const Duration(minutes: 3)) {
      return localData;
    }

    unawaited(_syncRemoteDataInBackground(user));
    return localData;
  }

  void _setupReactiveStreams(String userId) {
    if (_tarefasHabitosSub == null) {
      if (userId.isNotEmpty) {
        final stream = repository.watchTarefasEHabitos(usuarioId: userId);
        _tarefasHabitosSub = stream.listen((data) {
          mobx.runInAction(() {
            _tarefasHabitosList.clear();
            _tarefasHabitosList.addAll(data);
          });
        });
      }
    }
  }

  Future<void> _syncRemoteDataInBackground(String user) async {
    mobx.runInAction(() {
      _isSyncing.value = true;
    });
    try {
      final String? lastTarefasSyncStr = await Core.database.getSetting(
        'last_tarefas_habitos_sync_time',
      );
      final DateTime? lastTarefasSyncedAt = lastTarefasSyncStr != null
          ? DateTime.tryParse(lastTarefasSyncStr)
          : null;

      final String? lastHistoricoSyncStr = await Core.database.getSetting(
        'last_historico_sync_time',
      );
      final DateTime? lastHistoricoSyncedAt = lastHistoricoSyncStr != null
          ? DateTime.tryParse(lastHistoricoSyncStr)
          : null;

      await repository.getTarefasEHabitos(
        usuarioId: user,
        lastSyncedAt: lastTarefasSyncedAt,
      );
      await repository.getHistorico(
        usuarioId: user,
        lastSyncedAt: lastHistoricoSyncedAt,
      );
      final now = DateTime.now();
      _lastSyncTime = now;
      await Core.database.setSetting(
        'last_tarefas_habitos_sync_time',
        now.toIso8601String(),
      );
      await Core.database.setSetting(
        'last_historico_sync_time',
        now.toIso8601String(),
      );
    } catch (e) {
      log('Background sync failed for Tarefas/Habitos: $e');
    } finally {
      mobx.runInAction(() {
        _isSyncing.value = false;
      });
    }
  }

  void reset() {
    _tarefasHabitosSub?.cancel();
    _tarefasHabitosSub = null;
    _lastSyncTime = null;
    mobx.runInAction(() {
      _tarefasHabitosList.clear();
      _isSyncing.value = false;
    });
    tarefasHabitosFuture = null;
  }

  void updateCategoryInLoadedTasks(
    CategoriasTarefasHabitosModel updatedCategory,
  ) {
    mobx.runInAction(() {
      for (int i = 0; i < _tarefasHabitosList.length; i++) {
        final task = _tarefasHabitosList[i];
        bool changed = false;
        final newMetas = task.tarefasHabitosQtd.map((qtd) {
          if (qtd.categoriasTarefasHabitos?.id == updatedCategory.id) {
            changed = true;
            return qtd.copyWith(categoriasTarefasHabitos: updatedCategory);
          }
          return qtd;
        }).toList();

        if (changed) {
          _tarefasHabitosList[i] = task.copyWith(tarefaHabitoQtd: newMetas);
        }
      }
    });
  }

  void removeCategoryFromLoadedTasks(String categoryId) {
    mobx.runInAction(() {
      for (int i = 0; i < _tarefasHabitosList.length; i++) {
        final task = _tarefasHabitosList[i];
        bool changed = false;
        final newMetas = task.tarefasHabitosQtd.map((qtd) {
          if (qtd.categoriasTarefasHabitos?.id == categoryId) {
            changed = true;
            return qtd.copyWith(clearCategoria: true);
          }
          return qtd;
        }).toList();

        if (changed) {
          _tarefasHabitosList[i] = task.copyWith(tarefaHabitoQtd: newMetas);
        }
      }
    });
  }

  Future<void> addQtdHabito(String documentId) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String userId = Core.loginController.currentUser?.$id ?? '';

      mobx.runInAction(() {
        final List<TarefaHabitoModel> temp = List<TarefaHabitoModel>.from(
          _tarefasHabitosList.toList(),
        );
        final int index = temp.indexWhere((el) => el.id == documentId);
        if (index != -1) {
          final found = temp[index];
          final updatedMetas = found.tarefasHabitosQtd.map((element) {
            if (element.valor < 0) {
              return element.copyWith(vezesPraticado: 0);
            } else {
              return element.copyWith(
                vezesPraticado: element.vezesPraticado + element.valor,
              );
            }
          }).toList();
          temp[index] = found.copyWith(tarefaHabitoQtd: updatedMetas);
          _tarefasHabitosList.clear();
          _tarefasHabitosList.addAll(temp);
        }
      }, name: 'addQtdHabito');

      if (userId.isNotEmpty) {
        await repository.recordHistorico(
          foundId: documentId,
          usuarioId: userId,
        );
      }
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> incrementQtdHabito(String documentId) => addQtdHabito(documentId);

  Future<void> completeTarefa(String documentId) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String userId = Core.loginController.currentUser?.$id ?? '';

      bool isHabit = false;
      mobx.runInAction(() {
        final List<TarefaHabitoModel> temp = List<TarefaHabitoModel>.from(
          _tarefasHabitosList.toList(),
        );
        final int index = temp.indexWhere((el) => el.id == documentId);
        if (index != -1) {
          final found = temp[index];
          isHabit = found.tipo == 'habito';
          final updatedMetas = found.tarefasHabitosQtd.map((element) {
            if (element.valor < 0) {
              return element.copyWith(vezesPraticado: 0);
            } else {
              return element.copyWith(
                vezesPraticado: element.vezesPraticado + element.valor,
              );
            }
          }).toList();
          temp[index] = found.copyWith(
            concluida: !isHabit,
            tarefaHabitoQtd: updatedMetas,
          );
          _tarefasHabitosList.clear();
          _tarefasHabitosList.addAll(temp);
        }
      }, name: 'completeTarefa');

      if (userId.isNotEmpty) {
        await repository.recordHistorico(foundId: documentId, usuarioId: userId);
        if (!isHabit) {
          await repository.updateConcluida(documentId: documentId, concluida: true);
        }
      }
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<bool> createTarefaHabito({
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    DateTime? agendamento,
    int? duration,
    bool arquivado = false,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';

      final List<Map<String, dynamic>> metaDataList = metas
          .map(
            (meta) => {
              if (meta['id'] != null) 'id': meta['id'] as String?,
              if (meta['createdAt'] != null) 'createdAt': meta['createdAt'],
              'metaVezes': meta['metaVezes'] as int,
              'categoriaId': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
              if (meta['vezesPraticado'] != null)
                'vezesPraticado': meta['vezesPraticado'] as num?,
            },
          )
          .toList();

      await repository.createTarefaHabito(
        nome: nome,
        tipo: tipo,
        metas: metaDataList,
        agendamento: agendamento,
        duration: duration,
        arquivado: arquivado,
        usuarioId: user,
      );

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating task/habit: $e');
      return false;
    }
  }

  Future<bool> updateTarefaHabito({
    required String id,
    required String nome,
    required String tipo,
    required List<Map<String, dynamic>> metas,
    required List<String> allExistingQtdRowIds,
    DateTime? agendamento,
    int? duration,
    bool? arquivado,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';

      final List<Map<String, dynamic>> metaDataList = metas
          .map(
            (meta) => {
              'id': meta['id'] as String?,
              if (meta['createdAt'] != null) 'createdAt': meta['createdAt'],
              'metaVezes': meta['metaVezes'] as int,
              'categoriaId': meta['categoriaId'] as String?,
              'valor': meta['valor'] as num,
              'reiniciaEmQtd': meta['reiniciaEmQtd'] as int,
              'reiniciaEmTipo': meta['reiniciaEmTipo'] as String,
              if (meta['vezesPraticado'] != null)
                'vezesPraticado': meta['vezesPraticado'] as num?,
            },
          )
          .toList();

      await repository.updateTarefaHabito(
        id: id,
        nome: nome,
        tipo: tipo,
        metas: metaDataList,
        allExistingQtdRowIds: allExistingQtdRowIds,
        agendamento: agendamento,
        duration: duration,
        arquivado: arquivado,
        usuarioId: user,
      );

      final updatedLocal = await repository.getTarefasEHabitos(
        usuarioId: user,
        forceLocal: true,
      );
      mobx.runInAction(() {
        _tarefasHabitosList.clear();
        _tarefasHabitosList.addAll(updatedLocal);
      });

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating task/habit: $e');
      return false;
    }
  }

  Future<bool> deleteTarefaHabito(String id, List<String> qtdRowIds) async {
    try {
      await repository.deleteTarefaHabito(id: id, qtdRowIds: qtdRowIds);

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting task/habit: $e');
      return false;
    }
  }
}
