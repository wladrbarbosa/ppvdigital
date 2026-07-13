// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:ppvdigital/models/tarefas_habitos_model.dart';

class HistoricoItemModel {
  final String usuario;
  final String id;
  final TarefaHabitoModel tarefasEHabitos;
  final DateTime createdAt;

  HistoricoItemModel({
    required this.usuario,
    required this.id,
    required this.tarefasEHabitos,
    required this.createdAt,
  });

  HistoricoItemModel copyWith({
    String? usuario,
    String? id,
    TarefaHabitoModel? tarefasEHabitos,
    DateTime? createdAt,
  }) {
    return HistoricoItemModel(
      usuario: usuario ?? this.usuario,
      id: id ?? this.id,
      tarefasEHabitos: tarefasEHabitos ?? this.tarefasEHabitos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'usuario': usuario,
      'id': id,
      'tarefasEHabitos': tarefasEHabitos.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory HistoricoItemModel.fromMap(Map<String, dynamic> map) {
    return HistoricoItemModel(
      usuario: map['usuario'] as String,
      id: map['id'] as String,
      tarefasEHabitos: TarefaHabitoModel.fromMap(
        map['tarefasEHabitos'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoricoItemModel.fromJson(String source) =>
      HistoricoItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'HistoricoItem(usuario: $usuario, id: $id, tarefasEHabitos: $tarefasEHabitos, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant HistoricoItemModel other) {
    if (identical(this, other)) return true;

    return other.usuario == usuario &&
        other.id == id &&
        other.tarefasEHabitos == tarefasEHabitos &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return usuario.hashCode ^
        id.hashCode ^
        tarefasEHabitos.hashCode ^
        createdAt.hashCode;
  }
}
