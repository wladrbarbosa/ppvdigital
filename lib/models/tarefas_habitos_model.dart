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
  final int? duration;

  TarefaHabitoModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.usuario,
    required this.concluida,
    required this.agendamento,
    required this.tarefasHabitosQtd,
    this.duration,
  });

  TarefaHabitoModel copyWith({
    String? id,
    String? nome,
    String? tipo,
    String? usuario,
    bool? concluida,
    DateTime? agendamento,
    List<TarefaHabitoQtdModel>? tarefaHabitoQtd,
    int? duration,
  }) {
    return TarefaHabitoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      usuario: usuario ?? this.usuario,
      concluida: concluida ?? this.concluida,
      agendamento: agendamento ?? this.agendamento,
      tarefasHabitosQtd: tarefaHabitoQtd ?? tarefasHabitosQtd,
      duration: duration ?? this.duration,
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
      'duration': duration,
    };
  }

  factory TarefaHabitoModel.fromMap(Map<String, dynamic> map) {
    return TarefaHabitoModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      tipo: map['tipo'] as String,
      usuario: map['usuario'] as String,
      concluida: map['concluida'] as bool,
      agendamento: map['agendamento'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['agendamento'] as int)
          : null,
      tarefasHabitosQtd: List<TarefaHabitoQtdModel>.from(
        (map['tarefaHabitoQtd'] as List<dynamic>).map<TarefaHabitoQtdModel>(
          (x) => TarefaHabitoQtdModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      duration: map['duration'] is num
          ? (map['duration'] as num).toInt()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TarefaHabitoModel.fromJson(String source) =>
      TarefaHabitoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TarefaHabitoModel(id: $id, nome: $nome, tipo: $tipo, usuario: $usuario, concluida: $concluida, agendamento: $agendamento, tarefaHabitoQtd: $tarefasHabitosQtd, duration: $duration)';
  }

  @override
  bool operator ==(covariant TarefaHabitoModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.tipo == tipo &&
        other.usuario == usuario &&
        other.concluida == concluida &&
        other.agendamento == agendamento &&
        listEquals(other.tarefasHabitosQtd, tarefasHabitosQtd) &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        tipo.hashCode ^
        usuario.hashCode ^
        concluida.hashCode ^
        agendamento.hashCode ^
        tarefasHabitosQtd.hashCode ^
        duration.hashCode;
  }
}
