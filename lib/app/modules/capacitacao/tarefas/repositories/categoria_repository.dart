import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/categoria_model.dart';

class CategoriaRepository {
  CategoriaRepository(
    this.firebaseFirestore,
  );
  
  final FirebaseFirestore firebaseFirestore;

  Stream<List<CategoriaModel>> getCategorias() {
    return firebaseFirestore.collection('categorias').orderBy('nome', descending: true).snapshots().map((query) {
      return query.docs.map<CategoriaModel>((doc) {
        return CategoriaModel.fromDocument(doc);
      }).toList();
    });
  }

  void clearCategorias() {
    firebaseFirestore.collection('categorias').get().then((query) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> ds in query.docs) {
        ds.reference.delete();
      }
    });
  }

  Future<List<CategoriaModel>?>? getCategoriasOneShot() async {
    return (await firebaseFirestore.collection('categorias').get()).docs.map<CategoriaModel>((doc) => CategoriaModel.fromDocument(doc)).toList();
  }
}
