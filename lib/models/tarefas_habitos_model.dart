import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ppvdigital/models/enums.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';

class TarefaHabitoModel {
  TarefaHabitoModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.usuario,
    required this.concluida,
    this.arquivado = false,
    required this.agendamento,
    required this.tarefasHabitosQtd,
    this.duration,
  });

  factory TarefaHabitoModel.fromMap(Map<String, dynamic> map) {
    final String docId = (map[r'$id'] ?? map['id'] ?? '') as String;
    final dynamic rawMetas =
        map['metas'] ??
        map['tarefaHabitoQtd'] ??
        map['tarefasHabitosQtds'] ??
        map['tarefasHabitosQtd'];
    List<TarefaHabitoQtdModel> metas = [];
    if (rawMetas is List) {
      metas = rawMetas
          .whereType<Map>()
          .map(
            (x) => TarefaHabitoQtdModel.fromMap(Map<String, dynamic>.from(x)),
          )
          .toList();
    }
    final rawConcluida = map['concluida'];
    final bool isConcluida = rawConcluida is bool
        ? rawConcluida
        : (rawConcluida == 1 || rawConcluida == 'true' || rawConcluida == '1');

    final rawArquivado = map['arquivado'];
    final bool isArquivado = rawArquivado is bool
        ? rawArquivado
        : (rawArquivado == 1 || rawArquivado == 'true' || rawArquivado == '1');

    return TarefaHabitoModel(
      id: docId,
      nome: (map['nome'] ?? '') as String,
      tipo: (map['tipo'] ?? 'tarefa') as String,
      usuario: (map['usuario'] ?? '') as String,
      concluida: isConcluida,
      arquivado: isArquivado,
      agendamento: map['agendamento'] != null
          ? (map['agendamento'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['agendamento'] as int)
                : DateTime.tryParse(map['agendamento'].toString()))
          : null,
      tarefasHabitosQtd: metas,
      duration: map['duration'] is num
          ? (map['duration'] as num).toInt()
          : null,
    );
  }

  factory TarefaHabitoModel.fromJson(String source) =>
      TarefaHabitoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  final String id;
  final String nome;
  final String tipo;
  final String usuario;
  final bool concluida;
  final bool arquivado;
  final DateTime? agendamento;
  final List<TarefaHabitoQtdModel> tarefasHabitosQtd;
  final int? duration;

  TipoItem get tipoEnum => TipoItem.fromString(tipo);
  bool get isHabitoNegativo => tarefasHabitosQtd.any((q) => q.valor < 0);
  TipoHabito get tipoHabitoEnum =>
      isHabitoNegativo ? TipoHabito.negativo : TipoHabito.positivo;

  TarefaHabitoModel copyWith({
    String? id,
    String? nome,
    String? tipo,
    String? usuario,
    bool? concluida,
    bool? arquivado,
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
      arquivado: arquivado ?? this.arquivado,
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
      'arquivado': arquivado,
      'agendamento': agendamento?.millisecondsSinceEpoch,
      'tarefaHabitoQtd': tarefasHabitosQtd.map((x) => x.toMap()).toList(),
      'duration': duration,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'TarefaHabitoModel(id: $id, nome: $nome, tipo: $tipo, usuario: $usuario, concluida: $concluida, arquivado: $arquivado, agendamento: $agendamento, tarefaHabitoQtd: $tarefasHabitosQtd, duration: $duration)';
  }

  @override
  bool operator ==(covariant TarefaHabitoModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.nome == nome &&
        other.tipo == tipo &&
        other.usuario == usuario &&
        other.concluida == concluida &&
        other.arquivado == arquivado &&
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
        arquivado.hashCode ^
        agendamento.hashCode ^
        tarefasHabitosQtd.hashCode ^
        duration.hashCode;
  }
}
