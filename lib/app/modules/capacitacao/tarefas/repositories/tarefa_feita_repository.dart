import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_feita_model.dart';

class TarefaFeitaRepository {
  TarefaFeitaRepository(
    this.firebaseFirestore,
  );
  
  final FirebaseFirestore firebaseFirestore;

  Stream<List<TarefaFeitaModel>> getHistorico() {
    return firebaseFirestore.collection('tarefas_feitas').orderBy('dataHora', descending: true).snapshots().map((query) {
      return query.docs.map<TarefaFeitaModel>((doc) {
        return TarefaFeitaModel.fromDocument(doc);
      }).toList();
    });
  }

  void clearHistorico() {
    firebaseFirestore.collection('tarefas_feitas').get().then((query) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> ds in query.docs) {
        ds.reference.delete();
      }
    });
  }
}
