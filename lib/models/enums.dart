/// Enums tipados do domínio da aplicação com suporte a métodos do Dart 3 e serialização segura.
library;

enum TipoTransacao {
  despesa('despesa', 'Despesa'),
  receita('receita', 'Receita'),
  transferencia('transferencia', 'Transferência');

  const TipoTransacao(this.value, this.label);
  final String value;
  final String label;

  static TipoTransacao fromString(String? val) {
    if (val == null) return TipoTransacao.despesa;
    final normalized = val.trim().toLowerCase();
    for (final t in TipoTransacao.values) {
      if (t.value == normalized) return t;
    }
    return TipoTransacao.despesa;
  }

  bool get isDespesa => this == TipoTransacao.despesa;
  bool get isReceita => this == TipoTransacao.receita;
  bool get isTransferencia => this == TipoTransacao.transferencia;
}

enum TipoItem {
  tarefa('tarefa', 'Tarefa'),
  habito('habito', 'Hábito');

  const TipoItem(this.value, this.label);
  final String value;
  final String label;

  static TipoItem fromString(String? val) {
    if (val == null) return TipoItem.tarefa;
    final normalized = val.trim().toLowerCase();
    for (final t in TipoItem.values) {
      if (t.value == normalized) return t;
    }
    return TipoItem.tarefa;
  }

  bool get isTarefa => this == TipoItem.tarefa;
  bool get isHabito => this == TipoItem.habito;
}

enum TipoHabito {
  positivo('positivo', 'Positivo'),
  negativo('negativo', 'Negativo (Abstinência)');

  const TipoHabito(this.value, this.label);
  final String value;
  final String label;

  static TipoHabito fromString(String? val) {
    if (val == null) return TipoHabito.positivo;
    final normalized = val.trim().toLowerCase();
    for (final t in TipoHabito.values) {
      if (t.value == normalized) return t;
    }
    return TipoHabito.positivo;
  }

  bool get isPositivo => this == TipoHabito.positivo;
  bool get isNegativo => this == TipoHabito.negativo;
}

enum TipoRecorrencia {
  dia('dia', 'Diária'),
  semana('semana', 'Semanal'),
  mes('mês', 'Mensal'),
  ano('ano', 'Anual');

  const TipoRecorrencia(this.value, this.label);
  final String value;
  final String label;

  static TipoRecorrencia fromString(String? val) {
    if (val == null) return TipoRecorrencia.mes;
    final normalized = val.trim().toLowerCase();
    for (final t in TipoRecorrencia.values) {
      if (t.value == normalized || (t == TipoRecorrencia.mes && (normalized == 'mes' || normalized == 'mês'))) {
        return t;
      }
    }
    return TipoRecorrencia.mes;
  }
}
