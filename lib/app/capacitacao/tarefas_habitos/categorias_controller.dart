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
        usuario: e.data['usuario'] as String,
        nome: e.data['nome'] as String,
        cor: HexColor.fromHex(e.data['cor'] as String),
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

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }

        final TablesDB tablesDB = TablesDB(databases.client);
        final RowList docs = await tablesDB.listRows(
          databaseId: '671f6e1600022832cba5',
          tableId: '671f8803003d7d827ea8',
          queries: [
            Query.equal('usuario', [
              Core.loginController.currentUser?.$id ?? '',
            ]),
            Query.limit(5000),
          ],
        );

        _categoriasList.clear();
        _categoriasList.addAll(docs.rows.toCategoriasModelList());
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f8803003d7d827ea8',
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f8803003d7d827ea8',
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f8803003d7d827ea8',
        rowId: documentId,
      );

      mobx.runInAction(() {
        _categoriasList.removeWhere((el) => el.id == documentId);
      });
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
