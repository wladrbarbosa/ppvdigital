import 'dart:convert';

import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';

class TransacaoModel {
  TransacaoModel({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.dataCompetencia,
    this.contaDestino,
    this.conta,
    required this.consolidada,
    this.categoria,
    this.recorrencia,
    required this.divisoes,
    this.devedorContato,
    this.credorContato,
  });

  factory TransacaoModel.fromMap(Map<String, dynamic> map) {
    // Relationships can be full Maps or IDs.
    ContaModel? parsedConta;
    final dynamic rawConta = map['conta'];
    if (rawConta is Map) {
      parsedConta = ContaModel.fromMap(Map<String, dynamic>.from(rawConta));
    }

    ContaModel? parsedContaDestino;
    final dynamic rawContaDestino = map['contaDestino'];
    if (rawContaDestino is Map) {
      parsedContaDestino = ContaModel.fromMap(
        Map<String, dynamic>.from(rawContaDestino),
      );
    }

    CategoriaTransacaoModel? parsedCategoria;
    final dynamic rawCategoria = map['categoria'];
    if (rawCategoria is Map) {
      parsedCategoria = CategoriaTransacaoModel.fromMap(
        Map<String, dynamic>.from(rawCategoria),
      );
    }

    TransacaoRecorrenciaModel? parsedRecorrencia;
    final dynamic rawRecorrencia = map['recorrencia'];
    if (rawRecorrencia is Map) {
      parsedRecorrencia = TransacaoRecorrenciaModel.fromMap(
        Map<String, dynamic>.from(rawRecorrencia),
      );
    }

    final List<DivisaoTransacaoModel> parsedDivisoes = [];
    final dynamic rawDiv = map['divisoes'];
    if (rawDiv is List) {
      for (final el in rawDiv) {
        if (el is Map) {
          parsedDivisoes.add(
            DivisaoTransacaoModel.fromMap(Map<String, dynamic>.from(el)),
          );
        }
      }
    }

    ContatoModel? parsedDevedorContato;
    final dynamic rawDevedor = map['devedorContato'];
    if (rawDevedor is Map) {
      parsedDevedorContato = ContatoModel.fromMap(
        Map<String, dynamic>.from(rawDevedor),
      );
    }

    ContatoModel? parsedCredorContato;
    final dynamic rawCredor = map['credorContato'];
    if (rawCredor is Map) {
      parsedCredorContato = ContatoModel.fromMap(
        Map<String, dynamic>.from(rawCredor),
      );
    }

    return TransacaoModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      tipo: map['tipo'] as String? ?? 'despesa',
      dataCompetencia: parseDateCompetencia(
        map['dataCompetencia'] as String? ?? '',
      ),
      contaDestino: parsedContaDestino,
      conta: parsedConta,
      consolidada: map['consolidada'] as bool? ?? false,
      categoria: parsedCategoria,
      recorrencia: parsedRecorrencia,
      divisoes: parsedDivisoes,
      devedorContato: parsedDevedorContato,
      credorContato: parsedCredorContato,
    );
  }

  factory TransacaoModel.fromJson(String source) =>
      TransacaoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static DateTime parseDateCompetencia(String raw) {
    if (raw.length >= 10) {
      final datePart = raw.substring(0, 10);
      final parsed = DateTime.tryParse(datePart);
      if (parsed != null) return parsed;
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  final String id;
  final String descricao;
  final double valor;
  final String tipo; // despesa, receita, transferencia
  final DateTime dataCompetencia;
  final ContaModel? contaDestino;
  final ContaModel? conta;
  final bool consolidada;
  final CategoriaTransacaoModel? categoria;
  final TransacaoRecorrenciaModel? recorrencia;
  final List<DivisaoTransacaoModel> divisoes;
  final ContatoModel? devedorContato;
  final ContatoModel? credorContato;

  TransacaoModel copyWith({
    String? id,
    String? descricao,
    double? valor,
    String? tipo,
    DateTime? dataCompetencia,
    ContaModel? contaDestino,
    ContaModel? conta,
    bool? consolidada,
    CategoriaTransacaoModel? categoria,
    TransacaoRecorrenciaModel? recorrencia,
    List<DivisaoTransacaoModel>? divisoes,
    ContatoModel? devedorContato,
    ContatoModel? credorContato,
  }) {
    return TransacaoModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      dataCompetencia: dataCompetencia ?? this.dataCompetencia,
      contaDestino: contaDestino ?? this.contaDestino,
      conta: conta ?? this.conta,
      consolidada: consolidada ?? this.consolidada,
      categoria: categoria ?? this.categoria,
      recorrencia: recorrencia ?? this.recorrencia,
      divisoes: divisoes ?? this.divisoes,
      devedorContato: devedorContato ?? this.devedorContato,
      credorContato: credorContato ?? this.credorContato,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'dataCompetencia': dataCompetencia.toIso8601String(),
      'contaDestino': contaDestino?.id,
      'conta': conta?.id,
      'consolidada': consolidada,
      'categoria': categoria?.id,
      'recorrencia': recorrencia?.id,
      'devedorContato': devedorContato?.id,
      'credorContato': credorContato?.id,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'TransacaoModel(id: $id, descricao: $descricao, valor: $valor, tipo: $tipo, dataCompetencia: $dataCompetencia, contaDestino: $contaDestino, conta: $conta, consolidada: $consolidada, categoria: $categoria, recorrencia: $recorrencia, divisoes: $divisoes, devedorContato: $devedorContato, credorContato: $credorContato)';
  }

  @override
  bool operator ==(covariant TransacaoModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.descricao == descricao &&
        other.valor == valor &&
        other.tipo == tipo &&
        other.dataCompetencia == dataCompetencia &&
        other.contaDestino == contaDestino &&
        other.conta == conta &&
        other.consolidada == consolidada &&
        other.categoria == categoria &&
        other.recorrencia == recorrencia &&
        other.devedorContato == devedorContato &&
        other.credorContato == credorContato;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        descricao.hashCode ^
        valor.hashCode ^
        tipo.hashCode ^
        dataCompetencia.hashCode ^
        contaDestino.hashCode ^
        conta.hashCode ^
        consolidada.hashCode ^
        categoria.hashCode ^
        recorrencia.hashCode ^
        devedorContato.hashCode ^
        credorContato.hashCode;
  }
}
