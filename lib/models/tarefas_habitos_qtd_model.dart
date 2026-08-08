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

  static DateTime calculateStartPeriod({
    required DateTime createdAt,
    required String reiniciaEmTipo,
    required int reiniciaEmQtd,
    DateTime? referenceDate,
  }) {
    final DateTime ref = referenceDate ?? DateTime.now();
    final DateTime nowToday = DateTime(ref.year, ref.month, ref.day);

    switch (reiniciaEmTipo) {
      case 'dias':
        if (reiniciaEmQtd <= 1) {
          return nowToday;
        }
        final DateTime beginning = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
        if (nowToday.isBefore(beginning)) return beginning;
        final int daysDiff = nowToday.difference(beginning).inDays;
        final int cycles = daysDiff ~/ reiniciaEmQtd;
        return beginning.add(Duration(days: cycles * reiniciaEmQtd));

      case 'semanas':
        final DateTime mondayOfThisWeek = DateTime(
          nowToday.year,
          nowToday.month,
          nowToday.day - (nowToday.weekday - 1),
        );
        if (reiniciaEmQtd <= 1) {
          return mondayOfThisWeek;
        }
        final DateTime beginningMonday = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day - (createdAt.weekday - 1),
        );
        if (nowToday.isBefore(beginningMonday)) return beginningMonday;
        final int weeksDiff =
            mondayOfThisWeek.difference(beginningMonday).inDays ~/ 7;
        final int cycles = weeksDiff ~/ reiniciaEmQtd;
        return beginningMonday.add(Duration(days: cycles * 7 * reiniciaEmQtd));

      case 'meses':
        if (reiniciaEmQtd <= 1) {
          return DateTime(nowToday.year, nowToday.month);
        }
        final DateTime beginningFirst = DateTime(
          createdAt.year,
          createdAt.month,
        );
        if (nowToday.isBefore(beginningFirst)) return beginningFirst;
        final int monthDiff = (nowToday.year - beginningFirst.year) * 12 +
            (nowToday.month - beginningFirst.month);
        final int cycles = monthDiff < 0 ? 0 : (monthDiff ~/ reiniciaEmQtd);
        return DateTime(
          beginningFirst.year,
          beginningFirst.month + (cycles * reiniciaEmQtd),
        );

      case 'anos':
        if (reiniciaEmQtd <= 1) {
          return DateTime(nowToday.year);
        }
        final DateTime beginningJan1 = DateTime(createdAt.year);
        if (nowToday.isBefore(beginningJan1)) return beginningJan1;
        final int yearDiff = nowToday.year - beginningJan1.year;
        final int cycles = yearDiff < 0 ? 0 : (yearDiff ~/ reiniciaEmQtd);
        return DateTime(beginningJan1.year + (cycles * reiniciaEmQtd));

      default:
        return nowToday;
    }
  }

  static DateTime calculateEndPeriod(
    DateTime startPeriod,
    String reiniciaEmTipo,
    int reiniciaEmQtd,
  ) {
    final int qtd = reiniciaEmQtd <= 0 ? 1 : reiniciaEmQtd;
    switch (reiniciaEmTipo) {
      case 'dias':
        return startPeriod.add(Duration(days: qtd));
      case 'semanas':
        return startPeriod.add(Duration(days: 7 * qtd));
      case 'meses':
        return DateTime(startPeriod.year, startPeriod.month + qtd);
      case 'anos':
        return DateTime(startPeriod.year + qtd);
      default:
        return startPeriod.add(Duration(days: qtd));
    }
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

