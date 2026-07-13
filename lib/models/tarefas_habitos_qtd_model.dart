// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';

class TarefaHabitoQtdModel {
  final String id;
  final int metaVezes;
  final String usuario;
  final CategoriasTarefasHabitosModel? categoriasTarefasHabitos;
  final num valor;
  final int reiniciaEmQtd;
  final String reiniciaEmTipo;
  //campo virtual
  num vezesPraticado;
  final DateTime createdAt;

  TarefaHabitoQtdModel({
    required this.id,
    required this.metaVezes,
    required this.usuario,
    this.categoriasTarefasHabitos,
    required this.valor,
    required this.reiniciaEmQtd,
    required this.reiniciaEmTipo,
    required this.vezesPraticado,
    required this.createdAt,
  });

  TarefaHabitoQtdModel copyWith({
    String? id,
    int? metaVezes,
    String? usuario,
    CategoriasTarefasHabitosModel? categoriasTarefasHabitos,
    num? valor,
    int? reiniciaEmQtd,
    String? reiniciaEmTipo,
    num? vezesPraticado,
    DateTime? createdAt,
  }) {
    return TarefaHabitoQtdModel(
      id: id ?? this.id,
      metaVezes: metaVezes ?? this.metaVezes,
      usuario: usuario ?? this.usuario,
      categoriasTarefasHabitos:
          categoriasTarefasHabitos ?? this.categoriasTarefasHabitos,
      valor: valor ?? this.valor,
      reiniciaEmQtd: reiniciaEmQtd ?? this.reiniciaEmQtd,
      reiniciaEmTipo: reiniciaEmTipo ?? this.reiniciaEmTipo,
      vezesPraticado: vezesPraticado ?? this.vezesPraticado,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'metaVezes': metaVezes,
      'usuario': usuario,
      'categoriasTarefasHabitos': categoriasTarefasHabitos?.toMap(),
      'valor': valor,
      'reiniciaEmQtd': reiniciaEmQtd,
      'reiniciaEmTipo': reiniciaEmTipo,
      'vezesPraticado': vezesPraticado,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dataCriacao': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TarefaHabitoQtdModel.fromMap(Map<String, dynamic> map) {
    final int rawMs =
        (map['dataCriacao'] as int?) ??
        (map['createdAt'] as int?) ??
        DateTime.now().millisecondsSinceEpoch;
    return TarefaHabitoQtdModel(
      id: (map['id'] ?? map[r'$id'] ?? '') as String,
      metaVezes: (map['metaVezes'] as int?) ?? 1,
      usuario: (map['usuario'] as String?) ?? '',
      categoriasTarefasHabitos: map['categoriasTarefasHabitos'] != null
          ? CategoriasTarefasHabitosModel.fromMap(
              Map<String, dynamic>.from(map['categoriasTarefasHabitos'] as Map),
            )
          : null,
      valor: (map['valor'] as num?) ?? 1.0,
      reiniciaEmQtd: (map['reiniciaEmQtd'] as int?) ?? 1,
      reiniciaEmTipo: (map['reiniciaEmTipo'] as String?) ?? 'dias',
      vezesPraticado: (map['vezesPraticado'] as num?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(rawMs),
    );
  }

  String toJson() => json.encode(toMap());

  factory TarefaHabitoQtdModel.fromJson(String source) =>
      TarefaHabitoQtdModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TarefaHabitoQtdModel(id: $id, metaVezes: $metaVezes, usuario: $usuario, categoriasTarefasHabitos: $categoriasTarefasHabitos, valor: $valor, reiniciaEmQtd: $reiniciaEmQtd, reiniciaEmTipo: $reiniciaEmTipo, vezesPraticado: $vezesPraticado, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant TarefaHabitoQtdModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.metaVezes == metaVezes &&
        other.usuario == usuario &&
        other.categoriasTarefasHabitos == categoriasTarefasHabitos &&
        other.valor == valor &&
        other.reiniciaEmQtd == reiniciaEmQtd &&
        other.reiniciaEmTipo == reiniciaEmTipo &&
        other.vezesPraticado == vezesPraticado &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        metaVezes.hashCode ^
        usuario.hashCode ^
        categoriasTarefasHabitos.hashCode ^
        valor.hashCode ^
        reiniciaEmQtd.hashCode ^
        reiniciaEmTipo.hashCode ^
        vezesPraticado.hashCode ^
        createdAt.hashCode;
  }
}
