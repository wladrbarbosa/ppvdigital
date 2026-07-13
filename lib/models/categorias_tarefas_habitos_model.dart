// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:ui';

import 'package:ppvdigital/core.dart';

class CategoriasTarefasHabitosModel {
  final String id;
  final String nome;
  final String? pai;
  final Color cor;
  final String usuario;

  CategoriasTarefasHabitosModel({
    required this.id,
    required this.nome,
    this.pai,
    required this.cor,
    required this.usuario,
  });

  CategoriasTarefasHabitosModel copyWith({
    String? id,
    String? nome,
    String? pai,
    Color? cor,
    String? usuario,
  }) {
    return CategoriasTarefasHabitosModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      pai: pai ?? this.pai,
      cor: cor ?? this.cor,
      usuario: usuario ?? this.usuario,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'pai': pai,
      'cor': cor.toHex(leadingHashSign: false),
      'usuario': usuario,
    };
  }

  factory CategoriasTarefasHabitosModel.fromMap(Map<String, dynamic> map) {
    return CategoriasTarefasHabitosModel(
      id: (map['id'] ?? map[r'$id'] ?? '') as String,
      nome: (map['nome'] as String?) ?? '',
      pai: map['pai'] as String?,
      cor: HexColor.fromHex((map['cor'] as String?) ?? '#000000'),
      usuario: (map['usuario'] as String?) ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoriasTarefasHabitosModel.fromJson(String source) =>
      CategoriasTarefasHabitosModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'CategoriasTarefasHabitosModel(id: $id, nome: $nome, pai: $pai, cor: ${cor.toHex(leadingHashSign: false)}, usuario: $usuario)';
  }

  @override
  bool operator ==(covariant CategoriasTarefasHabitosModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.pai == pai &&
        other.cor == cor &&
        other.usuario == usuario;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        pai.hashCode ^
        cor.hashCode ^
        usuario.hashCode;
  }
}
