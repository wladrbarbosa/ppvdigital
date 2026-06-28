import 'dart:convert';

class ContaModel {
  final String id;
  final String name;
  final String userId;
  final double saldoAtual;

  ContaModel({
    required this.id,
    required this.name,
    required this.userId,
    required this.saldoAtual,
  });

  ContaModel copyWith({
    String? id,
    String? name,
    String? userId,
    double? saldoAtual,
  }) {
    return ContaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      saldoAtual: saldoAtual ?? this.saldoAtual,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'userId': userId,
      'saldoAtual': saldoAtual,
    };
  }

  factory ContaModel.fromMap(Map<String, dynamic> map) {
    return ContaModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      saldoAtual: (map['saldoAtual'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ContaModel.fromJson(String source) =>
      ContaModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ContaModel(id: $id, name: $name, userId: $userId, saldoAtual: $saldoAtual)';
  }

  @override
  bool operator ==(covariant ContaModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.name == name &&
        other.userId == userId &&
        other.saldoAtual == saldoAtual;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ userId.hashCode ^ saldoAtual.hashCode;
  }
}
