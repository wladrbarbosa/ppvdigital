import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';

class TarefasHabitosController {
  // Constructor
  TarefasHabitosController() {
    init();
  }

  late final Databases databases;
  final mobx.ObservableList<Document> _tarefasHabitosList = mobx.ObservableList<Document>(name: 'tarefasHabitosList');
  List<Document> get tarefasHabitosList => _tarefasHabitosList.toList();

  // Initialize the Appwrite client
  void init() {
    databases = Databases(Core.client);
  }

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        final DocumentList result = await databases.listDocuments(
          databaseId: '671f6e1600022832cba5',
          collectionId: '671f864f0023d1c27de8',
          queries: [
            Query.equal('usuario', [Core.instance.loginController.currentUser?.$id ?? '']),
          ],
        );
        _tarefasHabitosList.clear();
        _tarefasHabitosList.addAll(result.documents);
        return true;
      } on AppwriteException catch(e) {
        log(e.toString());
        return false;
      }
    },
    name: 'loadDocuments',);
  }

  Future<void> updateQtdHabito(String documentId, int newQtd) async {
    log('Começo');
    try {
      mobx.runInAction(() async {
        final List<Document> temp = List<Document>.from(_tarefasHabitosList.toList());
        final Document found = temp.singleWhere((el) => el.$id == documentId,);
        found.data['vezes_praticado'] = newQtd;
        _tarefasHabitosList.setAll(0, temp);
        databases.updateDocument(
          databaseId: '671f6e1600022832cba5',
          collectionId: '671f864f0023d1c27de8',
          documentId: documentId,
          data: {'vezes_praticado': found.data['vezes_praticado']},
        );
      },
      name: 'addQtdHabito',);
    } on AppwriteException catch(e) {
      log(e.toString());
    }
  }
}
