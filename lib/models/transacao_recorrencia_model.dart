import 'dart:convert';

class TransacaoRecorrenciaModel {
  TransacaoRecorrenciaModel({
    required this.id,
    required this.tipoRecorrencia,
    this.frequencia,
    this.totalParcelas,
    this.parcelaInicio,
    this.fimRecorrencia,
  });

  factory TransacaoRecorrenciaModel.fromMap(Map<String, dynamic> map) {
    DateTime? parsedFim;
    final String? fimStr = map['fimRecorrencia'] as String?;
    if (fimStr != null && fimStr.trim().isNotEmpty) {
      parsedFim = DateTime.tryParse(fimStr);
    }

    return TransacaoRecorrenciaModel(
      id: map[r'$id'] as String? ?? map['id'] as String? ?? '',
      tipoRecorrencia: map['tipoRecorrencia'] as String? ?? 'mês',
      frequencia: map['frequencia'] as int?,
      totalParcelas: map['totalParcelas'] as int?,
      parcelaInicio: map['parcelaInicio'] as int?,
      fimRecorrencia: parsedFim,
    );
  }

  factory TransacaoRecorrenciaModel.fromJson(String source) =>
      TransacaoRecorrenciaModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
  final String id;
  final String tipoRecorrencia;
  final int? frequencia;
  final int? totalParcelas;
  final int? parcelaInicio;
  final DateTime? fimRecorrencia;

  TransacaoRecorrenciaModel copyWith({
    String? id,
    String? tipoRecorrencia,
    int? frequencia,
    int? totalParcelas,
    int? parcelaInicio,
    DateTime? fimRecorrencia,
  }) {
    return TransacaoRecorrenciaModel(
      id: id ?? this.id,
      tipoRecorrencia: tipoRecorrencia ?? this.tipoRecorrencia,
      frequencia: frequencia ?? this.frequencia,
      totalParcelas: totalParcelas ?? this.totalParcelas,
      parcelaInicio: parcelaInicio ?? this.parcelaInicio,
      fimRecorrencia: fimRecorrencia ?? this.fimRecorrencia,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tipoRecorrencia': tipoRecorrencia,
      'frequencia': frequencia,
      'totalParcelas': totalParcelas,
      'parcelaInicio': parcelaInicio,
      'fimRecorrencia': fimRecorrencia?.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'TransacaoRecorrenciaModel(id: $id, tipoRecorrencia: $tipoRecorrencia, frequencia: $frequencia, totalParcelas: $totalParcelas, parcelaInicio: $parcelaInicio, fimRecorrencia: $fimRecorrencia)';
  }

  @override
  bool operator ==(covariant TransacaoRecorrenciaModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.tipoRecorrencia == tipoRecorrencia &&
        other.frequencia == frequencia &&
        other.totalParcelas == totalParcelas &&
        other.parcelaInicio == parcelaInicio &&
        other.fimRecorrencia == fimRecorrencia;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tipoRecorrencia.hashCode ^
        frequencia.hashCode ^
        totalParcelas.hashCode ^
        parcelaInicio.hashCode ^
        fimRecorrencia.hashCode;
  }
}
