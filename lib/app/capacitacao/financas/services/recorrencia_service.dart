import 'package:ppvdigital/models/enums.dart';

class RecorrenciaParcelaInfo {
  const RecorrenciaParcelaInfo({
    required this.index,
    required this.numeroParcela,
    required this.dataCompetencia,
    required this.descricao,
  });

  final int index;
  final int numeroParcela;
  final DateTime dataCompetencia;
  final String descricao;
}

class RecorrenciaService {
  const RecorrenciaService();

  /// Calcula a data de uma parcela futura baseada no tipo de recorrência e frequência usando Dart 3 Switch Expressions.
  static DateTime calcularDataParcela({
    required DateTime dataBase,
    required String tipoRecorrencia,
    required int frequencia,
    required int stepIndex,
  }) {
    if (stepIndex == 0) return dataBase;
    final tipo = TipoRecorrencia.fromString(tipoRecorrencia);

    return switch (tipo) {
      TipoRecorrencia.dia => dataBase.add(Duration(days: stepIndex * frequencia)),
      TipoRecorrencia.semana => dataBase.add(Duration(days: stepIndex * 7 * frequencia)),
      TipoRecorrencia.mes => DateTime(
          dataBase.year,
          dataBase.month + (stepIndex * frequencia),
          dataBase.day,
          dataBase.hour,
          dataBase.minute,
          dataBase.second,
          dataBase.millisecond,
        ),
      TipoRecorrencia.ano => DateTime(
          dataBase.year + (stepIndex * frequencia),
          dataBase.month,
          dataBase.day,
          dataBase.hour,
          dataBase.minute,
          dataBase.second,
          dataBase.millisecond,
        ),
    };
  }

  static String formatarDescricaoParcela({
    required String descricaoBase,
    bool recorrente = false,
    bool recorrenciaIndeterminada = false,
    int parcelaAtual = 1,
    int totalParcelas = 1,
  }) {
    if (!recorrente || recorrenciaIndeterminada || totalParcelas <= 1) {
      return descricaoBase;
    }
    return '$descricaoBase (Parcela $parcelaAtual/$totalParcelas)';
  }

  /// Gera a lista completa de informações das parcelas a serem criadas.
  static List<RecorrenciaParcelaInfo> gerarParcelas({
    required String descricao,
    required DateTime dataCompetencia,
    bool recorrente = false,
    bool recorrenciaIndeterminada = false,
    required String tipoRecorrencia,
    int frequencia = 1,
    int totalParcelas = 1,
    int parcelaInicio = 1,
  }) {
    final int remainingParcels = totalParcelas - parcelaInicio + 1;
    final int count = recorrente
        ? (recorrenciaIndeterminada ? 24 : remainingParcels.clamp(1, 999))
        : 1;

    final List<RecorrenciaParcelaInfo> parcelas = [];
    for (int i = 0; i < count; i++) {
      final data = calcularDataParcela(
        dataBase: dataCompetencia,
        tipoRecorrencia: tipoRecorrencia,
        frequencia: frequencia,
        stepIndex: i,
      );
      final parcelaNum = parcelaInicio + i;
      final descFinal = formatarDescricaoParcela(
        descricaoBase: descricao,
        recorrente: recorrente,
        recorrenciaIndeterminada: recorrenciaIndeterminada,
        parcelaAtual: parcelaNum,
        totalParcelas: totalParcelas,
      );

      parcelas.add(
        RecorrenciaParcelaInfo(
          index: i + 1,
          numeroParcela: parcelaNum,
          dataCompetencia: data,
          descricao: descFinal,
        ),
      );
    }
    return parcelas;
  }
}
