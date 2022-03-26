import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_model.dart';

class TarefaRepository {
  TarefaRepository(
    this.firebaseFirestore,
  );
  
  final FirebaseFirestore firebaseFirestore; 

  Stream<List<TarefaModel>> getTarefas() {
    return firebaseFirestore.collection('tarefas').orderBy('valor', descending: true).snapshots().map((query) {
      return query.docs.map<TarefaModel>((doc) {
        return TarefaModel.fromDocument(doc);
      }).toList();
    });
  }

  void clearTarefas() {
    firebaseFirestore.collection('tarefas').get().then((query) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> ds in query.docs) {
        ds.reference.delete();
      }
    });
  }
}
