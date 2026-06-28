import 'dart:convert';

class DivisaoTransacaoModel {
  final String id;
  final String transacaoId;
  final String userId;
  final double peso;

  DivisaoTransacaoModel({
    required this.id,
    required this.transacaoId,
    required this.userId,
    required this.peso,
  });

  DivisaoTransacaoModel copyWith({
    String? id,
    String? transacaoId,
    String? userId,
    double? peso,
  }) {
    return DivisaoTransacaoModel(
      id: id ?? this.id,
      transacaoId: transacaoId ?? this.transacaoId,
      userId: userId ?? this.userId,
      peso: peso ?? this.peso,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'transacao': transacaoId,
      'userId': userId,
      'peso': peso,
    };
  }

  factory DivisaoTransacaoModel.fromMap(Map<String, dynamic> map) {
    // transacao relationship might be a string or a nested map
    String tId = '';
    final dynamic tVal = map['transacao'];
    if (tVal is String) {
      tId = tVal;
    } else if (tVal is Map) {
      tId = (tVal[r'$id'] ?? tVal['id'] ?? '') as String;
    }

    return DivisaoTransacaoModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      transacaoId: tId,
      userId: map['userId'] as String? ?? '',
      peso: (map['peso'] as num?)?.toDouble() ?? 1.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory DivisaoTransacaoModel.fromJson(String source) =>
      DivisaoTransacaoModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'DivisaoTransacaoModel(id: $id, transacaoId: $transacaoId, userId: $userId, peso: $peso)';
  }

  @override
  bool operator ==(covariant DivisaoTransacaoModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.transacaoId == transacaoId &&
        other.userId == userId &&
        other.peso == peso;
  }

  @override
  int get hashCode {
    return id.hashCode ^ transacaoId.hashCode ^ userId.hashCode ^ peso.hashCode;
  }
}
