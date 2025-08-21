// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

class TarefaHabitoModel {
  final String id;
  final String nome;
  final String tipo;
  final String usuario;
  final bool concluida;
  final DateTime? agendamento;
  final List<TarefaHabitoQtdModel> tarefasHabitosQtd;
  
  TarefaHabitoModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.usuario,
    required this.concluida,
    required this.agendamento,
    required this.tarefasHabitosQtd,
  });

  TarefaHabitoModel copyWith({
    String? id,
    String? nome,
    String? tipo,
    String? usuario,
    bool? concluida,
    DateTime? agendamento,
    List<TarefaHabitoQtdModel>? tarefaHabitoQtd,
  }) {
    return TarefaHabitoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      usuario: usuario ?? this.usuario,
      concluida: concluida ?? this.concluida,
      agendamento: agendamento ?? this.agendamento,
      tarefasHabitosQtd: tarefaHabitoQtd ?? tarefasHabitosQtd,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'usuario': usuario,
      'concluida': concluida,
      'agendamento': agendamento?.millisecondsSinceEpoch,
      'tarefaHabitoQtd': tarefasHabitosQtd.map((x) => x.toMap()).toList(),
    };
  }

  factory TarefaHabitoModel.fromMap(Map<String, dynamic> map) {
    return TarefaHabitoModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String,
      usuario: map['usuario'] as String,
      concluida: map['concluida'] as bool,
      agendamento: DateTime.fromMillisecondsSinceEpoch(map['agendamento'] as int),
      tarefasHabitosQtd: List<TarefaHabitoQtdModel>.from((map['tarefaHabitoQtd'] as List<int>).map<TarefaHabitoQtdModel>((x) => TarefaHabitoQtdModel.fromMap(x as Map<String,dynamic>),),),
    );
  }

  String toJson() => json.encode(toMap());

  factory TarefaHabitoModel.fromJson(String source) => TarefaHabitoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TarefaHabitoModel(id: $id, nome: $nome, tipo: $tipo, usuario: $usuario, concluida: $concluida, agendamento: $agendamento, tarefaHabitoQtd: $tarefasHabitosQtd)';
  }

  @override
  bool operator ==(covariant TarefaHabitoModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.nome == nome &&
      other.tipo == tipo &&
      other.usuario == usuario &&
      other.concluida == concluida &&
      other.agendamento == agendamento &&
      listEquals(other.tarefasHabitosQtd, tarefasHabitosQtd);
  }

  @override
  int get hashCode {
    return id.hashCode ^
      nome.hashCode ^
      tipo.hashCode ^
      usuario.hashCode ^
      concluida.hashCode ^
      agendamento.hashCode ^
      tarefasHabitosQtd.hashCode;
  }
}
