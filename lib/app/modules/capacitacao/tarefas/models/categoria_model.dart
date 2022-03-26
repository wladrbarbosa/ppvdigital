import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriaModel {
  CategoriaModel({
    this.nome = '',
    this.dataCriacao,
    this.dataAtualizacao,
    this.minimoAnual = 0,
    this.minimoDiario = 0,
    this.minimoMensal = 0,
    this.minimoSemanal = 0,
    this.reference,
  });

  
  factory CategoriaModel.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return CategoriaModel(
      nome: doc['nome'] as String,
      dataCriacao: doc['dataCriacao'] as Timestamp,
      dataAtualizacao: doc['dataAtualizacao'] as Timestamp,
      minimoAnual: doc['minimoAnual'] as int,
      minimoDiario: doc['minimoDiario'] as int,
      minimoMensal: doc['minimoMensal'] as int,
      minimoSemanal: doc['minimoSemanal'] as int,
      reference: doc.reference,
    );
  }

  String nome;
  Timestamp? dataCriacao;
  Timestamp? dataAtualizacao;
  int minimoAnual;
  int minimoDiario;
  int minimoMensal;
  int minimoSemanal;
  DocumentReference? reference;

  Future<void> save() async {
    if (reference == null) {
      reference = await FirebaseFirestore.instance.collection('categorias').add({
        'nome': nome,
        'dataCriacao': Timestamp.now(),
        'dataAtualizacao': Timestamp.now(),
        'minimoAnual': minimoAnual,
        'minimoDiario': minimoDiario,
        'minimoMensal': minimoMensal,
        'minimoSemanal': minimoSemanal,
      });
    }
    else {
      await reference!.update({
        'nome': nome,
        'dataCriacao': dataCriacao,
        'dataAtualizacao': Timestamp.now(),
        'minimoAnual': minimoAnual,
        'minimoDiario': minimoDiario,
        'minimoMensal': minimoMensal,
        'minimoSemanal': minimoSemanal,
      });
    }
  }

  void delete() {
    reference!.delete();
  }
}
