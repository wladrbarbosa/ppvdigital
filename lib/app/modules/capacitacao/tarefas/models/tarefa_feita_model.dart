import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaFeitaModel {
  TarefaFeitaModel({
    this.tarefa,
    this.dataHora,
    this.reference,
  });

  
  factory TarefaFeitaModel.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return TarefaFeitaModel(
      tarefa: doc['tarefa'] as DocumentReference<Object?>?,
      dataHora: doc['dataHora'] as Timestamp,
      reference: doc.reference,
    );
  }

  DocumentReference? tarefa;
  Timestamp? dataHora;
  DocumentReference? reference;

  Future<void> save() async {
    if (reference == null) {
      reference = await FirebaseFirestore.instance.collection('tarefas_feitas').add({
        'tarefa': tarefa,
        'dataHora': Timestamp.now(),
      });
    }
    else {
      await reference!.update({
        'tarefa': tarefa,
        'dataHora': dataHora,
      });
    }
  }

  void delete() {
    reference!.delete();
  }
}
