import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';

class CategoriaTransacaoModel {
  CategoriaTransacaoModel({
    required this.id,
    required this.userId,
    required this.name,
    this.icone,
    this.cor,
  });

  factory CategoriaTransacaoModel.fromMap(Map<String, dynamic> map) {
    Color? colorParsed;
    final String? hexStr = map['cor'] as String?;
    if (hexStr != null && hexStr.trim().isNotEmpty) {
      try {
        colorParsed = HexColor.fromHex(hexStr);
      } catch (_) {}
    }

    return CategoriaTransacaoModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icone: map['icone'] as String?,
      cor: colorParsed,
    );
  }

  factory CategoriaTransacaoModel.fromJson(String source) =>
      CategoriaTransacaoModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
  final String id;
  final String userId;
  final String name;
  final String? icone;
  final Color? cor;

  CategoriaTransacaoModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icone,
    Color? cor,
  }) {
    return CategoriaTransacaoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'name': name,
      'icone': icone,
      'cor': cor?.toHex(leadingHashSign: false),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'CategoriaTransacaoModel(id: $id, userId: $userId, name: $name, icone: $icone, cor: $cor)';
  }

  @override
  bool operator ==(covariant CategoriaTransacaoModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.icone == icone &&
        other.cor == cor;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        icone.hashCode ^
        cor.hashCode;
  }
}
