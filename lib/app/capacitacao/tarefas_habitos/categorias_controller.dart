import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';

extension CategoriasTransformRowList on List<Row> {
  List<CategoriasTarefasHabitosModel> toCategoriasModelList() {
    return map(
      (e) => CategoriasTarefasHabitosModel(
        id: e.$id,
        usuario: (e.data['usuario'] as String?) ?? '',
        nome: (e.data['nome'] as String?) ?? '',
        cor: HexColor.fromHex((e.data['cor'] as String?) ?? '#000000'),
        pai: e.data['pai'] as String?,
      ),
    ).toList();
  }
}

class CategoriasController {
  CategoriasController() {
    init();
  }

  late final Databases databases;
  final mobx.ObservableList<CategoriasTarefasHabitosModel> _categoriasList =
      mobx.ObservableList<CategoriasTarefasHabitosModel>(
        name: 'categoriasList',
      );
  List<CategoriasTarefasHabitosModel> get categoriasList =>
      _categoriasList.toList();

  static Future<void>? categoriasFuture;

  void init() {
    databases = Databases(Core.client);
  }

  Future<void> _saveCache() async {
    try {
      final listMap = _categoriasList.map((c) => c.toMap()).toList();
      await Core.database.setSetting(
        'cached_categorias_tarefas_habitos_json',
        json.encode(listMap),
      );
    } catch (e) {
      log('Error saving categorias cache: $e');
    }
  }

  Future<void> _loadCache() async {
    try {
      final cachedJson = await Core.database.getSetting(
        'cached_categorias_tarefas_habitos_json',
      );
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final list = json.decode(cachedJson) as List;
        final loaded = list
            .map(
              (item) => CategoriasTarefasHabitosModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
        mobx.runInAction(() {
          _categoriasList.clear();
          _categoriasList.addAll(loaded);
        });
      }
    } catch (e) {
      log('Error loading cached categorias: $e');
    }
  }

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }

        final userId = Core.loginController.currentUser?.$id ?? '';

        if (_categoriasList.isEmpty) {
          await _loadCache();
        }

        final String? lastSyncStr = await Core.database.getSetting(
          'last_categorias_tarefas_habitos_sync_time',
        );
        final DateTime? lastSyncedAt = lastSyncStr != null
            ? DateTime.tryParse(lastSyncStr)
            : null;
        final now = DateTime.now();

        final TablesDB tablesDB = TablesDB(databases.client);
        final List<String> queries = [
          Query.equal('usuario', [userId]),
          Query.limit(5000),
        ];
        if (lastSyncedAt != null) {
          queries.add(
            Query.greaterThan(r'$updatedAt', lastSyncedAt.toIso8601String()),
          );
        }

        final RowList docs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableCategoriasTarefasHabitos,
          queries: queries,
        );

        final remoteItems = docs.rows.toCategoriasModelList();

        mobx.runInAction(() {
          if (lastSyncedAt == null) {
            _categoriasList.clear();
            _categoriasList.addAll(remoteItems);
          } else if (remoteItems.isNotEmpty) {
            for (final item in remoteItems) {
              final idx = _categoriasList.indexWhere((c) => c.id == item.id);
              if (idx != -1) {
                _categoriasList[idx] = item;
              } else {
                _categoriasList.add(item);
              }
            }
          }
        });

        await _saveCache();
        await Core.database.setSetting(
          'last_categorias_tarefas_habitos_sync_time',
          now.toIso8601String(),
        );

        return true;
      } on AppwriteException catch (e) {
        log(e.toString());
        return false;
      } on Exception catch (e) {
        log(e.toString());
        return false;
      }
    }, name: 'loadCategorias');
  }

  void reset() {
    mobx.runInAction(() {
      _categoriasList.clear();
    });
  }

  Future<bool> createCategory({
    required String nome,
    required Color cor,
    String? pai,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }

      final String hexColor = cor.toHex(leadingHashSign: false);
      final TablesDB tablesDB = TablesDB(databases.client);

      final Row row = await tablesDB.createRow(
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTarefasHabitos,
        rowId: ID.unique(),
        data: {
          'nome': nome,
          'cor': hexColor,
          'pai': pai,
          'usuario': Core.loginController.currentUser?.$id ?? '',
        },
      );

      mobx.runInAction(() {
        _categoriasList.add(
          CategoriasTarefasHabitosModel(
            id: row.$id,
            nome: nome,
            cor: cor,
            pai: pai,
            usuario: Core.loginController.currentUser?.$id ?? '',
          ),
        );
      });
      await _saveCache();
      return true;
    } on AppwriteException catch (e) {
      log(e.toString());
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String nome,
    required Color cor,
    String? pai,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }

      final String hexColor = cor.toHex(leadingHashSign: false);
      final TablesDB tablesDB = TablesDB(databases.client);

      await tablesDB.updateRow(
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTarefasHabitos,
        rowId: id,
        data: {
          'nome': nome,
          'cor': hexColor,
          'pai': pai,
          'usuario': Core.loginController.currentUser?.$id ?? '',
        },
      );

      mobx.runInAction(() {
        final index = _categoriasList.indexWhere((el) => el.id == id);
        if (index != -1) {
          _categoriasList[index] = CategoriasTarefasHabitosModel(
            id: id,
            nome: nome,
            cor: cor,
            pai: pai,
            usuario: Core.loginController.currentUser?.$id ?? '',
          );
        }
      });
      await _saveCache();
      return true;
    } on AppwriteException catch (e) {
      log(e.toString());
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String documentId) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.deleteRow(
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTarefasHabitos,
        rowId: documentId,
      );

      mobx.runInAction(() {
        _categoriasList.removeWhere((el) => el.id == documentId);
      });
      await _saveCache();
      return true;
    } on AppwriteException catch (e) {
      log(e.toString());
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}
