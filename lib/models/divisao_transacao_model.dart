import 'dart:convert';

class DivisaoTransacaoModel {
  DivisaoTransacaoModel({
    required this.id,
    required this.transacaoId,
    required this.contatoResponsavel,
    required this.peso,
  });

  factory DivisaoTransacaoModel.fromMap(Map<String, dynamic> map) {
    // transacao relationship might be a string or a nested map
    String tId = '';
    final dynamic tVal = map['transacao'];
    if (tVal is String) {
      tId = tVal;
    } else if (tVal is Map) {
      tId = (tVal[r'$id'] ?? tVal['id'] ?? '') as String;
    }

    String contatoId = '';
    final dynamic cVal = map['contatoResponsavel'];
    if (cVal is String) {
      contatoId = cVal;
    } else if (cVal is Map) {
      contatoId = (cVal[r'$id'] ?? cVal['id'] ?? '') as String;
    }

    return DivisaoTransacaoModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      transacaoId: tId,
      contatoResponsavel: contatoId,
      peso: (map['peso'] as num?)?.toDouble() ?? 1.0,
    );
  }

  factory DivisaoTransacaoModel.fromJson(String source) =>
      DivisaoTransacaoModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
  final String id;
  final String transacaoId;
  final String contatoResponsavel;
  final double peso;

  DivisaoTransacaoModel copyWith({
    String? id,
    String? transacaoId,
    String? contatoResponsavel,
    double? peso,
  }) {
    return DivisaoTransacaoModel(
      id: id ?? this.id,
      transacaoId: transacaoId ?? this.transacaoId,
      contatoResponsavel: contatoResponsavel ?? this.contatoResponsavel,
      peso: peso ?? this.peso,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'transacao': transacaoId,
      'contatoResponsavel': contatoResponsavel,
      'peso': peso,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'DivisaoTransacaoModel(id: $id, transacaoId: $transacaoId, contatoResponsavel: $contatoResponsavel, peso: $peso)';
  }

  @override
  bool operator ==(covariant DivisaoTransacaoModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.transacaoId == transacaoId &&
        other.contatoResponsavel == contatoResponsavel &&
        other.peso == peso;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        transacaoId.hashCode ^
        contatoResponsavel.hashCode ^
        peso.hashCode;
  }
}
