import 'dart:convert';

class ContatoModel {
  final String id;
  final String ownerId;
  final String nome;
  final String? telefone;
  final String? email;
  final String? userId;

  ContatoModel({
    required this.id,
    required this.ownerId,
    required this.nome,
    this.telefone,
    this.email,
    this.userId,
  });

  ContatoModel copyWith({
    String? id,
    String? ownerId,
    String? nome,
    String? telefone,
    String? email,
    String? userId,
  }) {
    return ContatoModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'nome': nome,
      'telefone': telefone,
      'email': email,
      'userId': userId,
    };
  }

  factory ContatoModel.fromMap(Map<String, dynamic> map) {
    return ContatoModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      telefone: map['telefone'] as String?,
      email: map['email'] as String?,
      userId: map['userId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ContatoModel.fromJson(String source) =>
      ContatoModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
