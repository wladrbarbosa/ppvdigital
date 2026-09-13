import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Sumário com a contagem de registros por tabela no arquivo de backup.
class BackupSummary {
  const BackupSummary({
    this.contas = 0,
    this.contatos = 0,
    this.categoriasTransacoes = 0,
    this.categoriasTarefasHabitos = 0,
    this.tarefasHabitosQtds = 0,
    this.transacaoRecorrencias = 0,
    this.tarefasEHabitos = 0,
    this.transacoes = 0,
    this.divisaoTransacoes = 0,
    this.historicoTarefasHabitos = 0,
  });

  factory BackupSummary.fromData(Map<String, List<Map<String, dynamic>>> data) {
    return BackupSummary(
      contas: data['contas']?.length ?? 0,
      contatos: data['contatos']?.length ?? 0,
      categoriasTransacoes: data['categoriasTransacoes']?.length ?? 0,
      categoriasTarefasHabitos: data['categoriasTarefasHabitos']?.length ?? 0,
      tarefasHabitosQtds: data['tarefasHabitosQtds']?.length ?? 0,
      transacaoRecorrencias: data['transacaoRecorrencias']?.length ?? 0,
      tarefasEHabitos: data['tarefasEHabitos']?.length ?? 0,
      transacoes: data['transacoes']?.length ?? 0,
      divisaoTransacoes: data['divisaoTransacoes']?.length ?? 0,
      historicoTarefasHabitos: data['historicoTarefasHabitos']?.length ?? 0,
    );
  }

  factory BackupSummary.fromMap(Map<String, dynamic> map) {
    return BackupSummary(
      contas: (map['contas'] as num?)?.toInt() ?? 0,
      contatos: (map['contatos'] as num?)?.toInt() ?? 0,
      categoriasTransacoes:
          (map['categoriasTransacoes'] as num?)?.toInt() ?? 0,
      categoriasTarefasHabitos:
          (map['categoriasTarefasHabitos'] as num?)?.toInt() ?? 0,
      tarefasHabitosQtds: (map['tarefasHabitosQtds'] as num?)?.toInt() ?? 0,
      transacaoRecorrencias:
          (map['transacaoRecorrencias'] as num?)?.toInt() ?? 0,
      tarefasEHabitos: (map['tarefasEHabitos'] as num?)?.toInt() ?? 0,
      transacoes: (map['transacoes'] as num?)?.toInt() ?? 0,
      divisaoTransacoes: (map['divisaoTransacoes'] as num?)?.toInt() ?? 0,
      historicoTarefasHabitos:
          (map['historicoTarefasHabitos'] as num?)?.toInt() ?? 0,
    );
  }

  final int contas;
  final int contatos;
  final int categoriasTransacoes;
  final int categoriasTarefasHabitos;
  final int tarefasHabitosQtds;
  final int transacaoRecorrencias;
  final int tarefasEHabitos;
  final int transacoes;
  final int divisaoTransacoes;
  final int historicoTarefasHabitos;

  int get totalRecords =>
      contas +
      contatos +
      categoriasTransacoes +
      categoriasTarefasHabitos +
      tarefasHabitosQtds +
      transacaoRecorrencias +
      tarefasEHabitos +
      transacoes +
      divisaoTransacoes +
      historicoTarefasHabitos;

  Map<String, dynamic> toMap() {
    return {
      'contas': contas,
      'contatos': contatos,
      'categoriasTransacoes': categoriasTransacoes,
      'categoriasTarefasHabitos': categoriasTarefasHabitos,
      'tarefasHabitosQtds': tarefasHabitosQtds,
      'transacaoRecorrencias': transacaoRecorrencias,
      'tarefasEHabitos': tarefasEHabitos,
      'transacoes': transacoes,
      'divisaoTransacoes': divisaoTransacoes,
      'historicoTarefasHabitos': historicoTarefasHabitos,
      'totalRecords': totalRecords,
    };
  }
}

/// Modelo canônico do payload de backup do usuário no PPVDigital.
///
/// Contém todos os dados das 10 tabelas do Appwrite vinculadas ao usuário,
/// metadados de auditoria e assinatura criptográfica SHA-256 para garantia
/// de integridade referencial e validação contra arquivos corrompidos.
class BackupPayloadModel {
  BackupPayloadModel({
    this.version = currentVersion,
    this.app = appIdentifier,
    required this.exportedAt,
    required this.userId,
    required this.userEmail,
    required this.data,
    String? checksum,
  }) : checksum = checksum ?? computeChecksum(data);

  factory BackupPayloadModel.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'] as Map<String, dynamic>? ?? {};
    final typedData = <String, List<Map<String, dynamic>>>{};

    for (final entry in rawData.entries) {
      if (entry.value is List) {
        typedData[entry.key] = (entry.value as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return BackupPayloadModel(
      version: (map['version'] as num?)?.toInt() ?? currentVersion,
      app: (map['app'] as String?) ?? appIdentifier,
      exportedAt: DateTime.tryParse(map['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      userId: (map['userId'] as String?) ?? '',
      userEmail: (map['userEmail'] as String?) ?? '',
      data: typedData,
      checksum: map['checksum'] as String?,
    );
  }

  factory BackupPayloadModel.fromJson(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Conteúdo do backup não é um objeto JSON válido.');
    }
    return BackupPayloadModel.fromMap(decoded);
  }

  static const int currentVersion = 1;
  static const String appIdentifier = 'PPVDigital';

  /// Nomes canônicos das 10 tabelas exportadas
  static const List<String> tableKeys = [
    'contas',
    'contatos',
    'categoriasTransacoes',
    'categoriasTarefasHabitos',
    'tarefasHabitosQtds',
    'transacaoRecorrencias',
    'tarefasEHabitos',
    'transacoes',
    'divisaoTransacoes',
    'historicoTarefasHabitos',
  ];

  final int version;
  final String app;
  final DateTime exportedAt;
  final String userId;
  final String userEmail;
  final Map<String, List<Map<String, dynamic>>> data;
  final String checksum;

  /// Retorna o resumo quantitativo de registros
  BackupSummary get summary => BackupSummary.fromData(data);

  /// Acesso facilitado para cada coleção
  List<Map<String, dynamic>> get contas => data['contas'] ?? [];
  List<Map<String, dynamic>> get contatos => data['contatos'] ?? [];
  List<Map<String, dynamic>> get categoriasTransacoes =>
      data['categoriasTransacoes'] ?? [];
  List<Map<String, dynamic>> get categoriasTarefasHabitos =>
      data['categoriasTarefasHabitos'] ?? [];
  List<Map<String, dynamic>> get tarefasHabitosQtds =>
      data['tarefasHabitosQtds'] ?? [];
  List<Map<String, dynamic>> get transacaoRecorrencias =>
      data['transacaoRecorrencias'] ?? [];
  List<Map<String, dynamic>> get tarefasEHabitos =>
      data['tarefasEHabitos'] ?? [];
  List<Map<String, dynamic>> get transacoes => data['transacoes'] ?? [];
  List<Map<String, dynamic>> get divisaoTransacoes =>
      data['divisaoTransacoes'] ?? [];
  List<Map<String, dynamic>> get historicoTarefasHabitos =>
      data['historicoTarefasHabitos'] ?? [];

  /// Calcula deterministicamente o checksum SHA-256 do payload de dados.
  static String computeChecksum(
      Map<String, List<Map<String, dynamic>>> dataMap) {
    // Ordena as chaves do dicionário para garantir serialização canônica invariante
    final sortedKeys = dataMap.keys.toList()..sort();
    final canonicalMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      canonicalMap[key] = dataMap[key];
    }
    final rawJson = json.encode(canonicalMap);
    final digest = sha256.convert(utf8.encode(rawJson));
    return 'sha256:$digest';
  }

  /// Verifica se o checksum declarado corresponde ao hash dos dados atuais.
  bool get isValidChecksum => checksum == computeChecksum(data);

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'app': app,
      'exportedAt': exportedAt.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'summary': summary.toMap(),
      'data': data,
      'checksum': checksum,
    };
  }

  String toJson({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toMap());
    }
    return json.encode(toMap());
  }
}
