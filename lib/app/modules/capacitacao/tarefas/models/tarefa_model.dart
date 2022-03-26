import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_feita_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/repositories/tarefa_feita_repository.dart';

class TarefaModel {
  TarefaModel({
    this.nome = '',
    this.dataCriacao,
    this.dataAtualizacao,
    this.valor = 0,
    this.categoria,
    this.reference,
  });

  factory TarefaModel.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return TarefaModel(
      nome: doc['nome'] as String,
      dataCriacao: doc['dataCriacao'] as Timestamp,
      dataAtualizacao: doc['dataAtualizacao'] as Timestamp,
      valor: doc['valor'] as int,
      categoria: doc['categoria'] as DocumentReference?,
      reference: doc.reference,
    );
  }

  String nome;
  Timestamp? dataCriacao;
  Timestamp? dataAtualizacao;
  int valor;
  DocumentReference? reference;
  DocumentReference? categoria;

  Future<void> save() async {
    if (reference == null) {
      reference = await FirebaseFirestore.instance.collection('tarefas').add({
        'nome': nome,
        'dataCriacao': Timestamp.now(),
        'dataAtualizacao': Timestamp.now(),
        'valor': valor,
        'categoria': categoria,
      });
    }
    else {
      await reference!.update({
        'nome': nome,
        'dataCriacao': dataCriacao,
        'dataAtualizacao': Timestamp.now(),
        'valor': valor,
        'categoria': categoria,
      });
    }
  }

  void delete() {
    reference!.delete();
  }

  Future<void> doTarefa(TarefaFeitaRepository tarefaFeitaRepo) async {
    final TarefaFeitaModel tarefaFeita = TarefaFeitaModel(
      dataHora: Timestamp.now(),
      tarefa: reference,
    );

    tarefaFeita.save();
  }
}
