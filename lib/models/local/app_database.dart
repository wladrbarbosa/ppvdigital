import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_qtd_model.dart';
import 'package:ppvdigital/models/transacao_recorrencia_model.dart';

part 'app_database.g.dart';

// Conversor JSON para listas/objetos de Metas (TarefaHabitoQtdModel)
class MetasConverter extends TypeConverter<List<TarefaHabitoQtdModel>, String> {
  const MetasConverter();

  @override
  List<TarefaHabitoQtdModel> fromSql(String fromDb) {
    try {
      final list = json.decode(fromDb) as List;
      return list
          .map(
            (item) => TarefaHabitoQtdModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e) {
      log('Error parsing metas from SQL: $e');
      return [];
    }
  }

  @override
  String toSql(List<TarefaHabitoQtdModel> value) {
    return json.encode(value.map((item) => item.toMap()).toList());
  }
}

// Conversor JSON para listas de Divisões (DivisaoTransacaoModel)
class DivisaoConverter
    extends TypeConverter<List<DivisaoTransacaoModel>, String> {
  const DivisaoConverter();

  @override
  List<DivisaoTransacaoModel> fromSql(String fromDb) {
    try {
      final list = json.decode(fromDb) as List;
      return list
          .map(
            (item) => DivisaoTransacaoModel.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e) {
      log('Error parsing divisoes from SQL: $e');
      return [];
    }
  }

  @override
  String toSql(List<DivisaoTransacaoModel> value) {
    return json.encode(value.map((item) => item.toMap()).toList());
  }
}

// Conversor JSON para Objeto de Recorrência (TransacaoRecorrenciaModel)
class RecorrenciaConverter
    extends TypeConverter<TransacaoRecorrenciaModel, String> {
  const RecorrenciaConverter();

  @override
  TransacaoRecorrenciaModel fromSql(String fromDb) {
    try {
      final map = json.decode(fromDb) as Map;
      return TransacaoRecorrenciaModel.fromMap(Map<String, dynamic>.from(map));
    } catch (e) {
      log('Error parsing recorrencia from SQL: $e');
      return TransacaoRecorrenciaModel(
        id: '',
        tipoRecorrencia: 'mês',
        frequencia: 1,
      );
    }
  }

  @override
  String toSql(TransacaoRecorrenciaModel value) {
    return json.encode(value.toMap());
  }
}

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

class TarefaHabitos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get nome => text()();
  TextColumn get tipo => text()();
  TextColumn get usuario => text()();
  BoolColumn get concluida => boolean()();
  DateTimeColumn get agendamento => dateTime().nullable()();
  IntColumn get duration => integer().nullable()();
  TextColumn get metas =>
      text().map(const MetasConverter())(); // Embutido como JSON
}

class HistoricoTarefasHabitos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get usuario => text()();
  TextColumn get tarefaHabitoId => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class Contas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get name => text()();
  TextColumn get userId => text()();
  RealColumn get saldoAtual => real()();
}

class Contatos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get ownerId => text()();
  TextColumn get nome => text()();
  TextColumn get telefone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get userId => text().nullable()();
}

class CategoriaTransacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get nome => text()();
  TextColumn get icone => text().nullable()();
  TextColumn get corHex => text()();
  TextColumn get userId => text()();
}

class Transacaos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get descricao => text()();
  RealColumn get valor => real()();
  TextColumn get tipo => text()();
  DateTimeColumn get dataCompetencia => dateTime()();
  BoolColumn get consolidada => boolean().withDefault(const Constant(false))();
  TextColumn get contaId => text().nullable()();
  TextColumn get contaDestinoId => text().nullable()();
  TextColumn get categoriaId => text().nullable()();
  TextColumn get devedorContatoId => text().nullable()();
  TextColumn get credorContatoId => text().nullable()();
  TextColumn get divisoes =>
      text().map(const DivisaoConverter())(); // Embutido como JSON
  TextColumn get recorrencia => text()
      .map(const RecorrenciaConverter())
      .nullable()(); // Embutido como JSON
}

@DriftDatabase(
  tables: [
    AppSettings,
    TarefaHabitos,
    HistoricoTarefasHabitos,
    Contas,
    Contatos,
    CategoriaTransacoes,
    Transacaos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 3) {
          try {
            await m.createTable(historicoTarefasHabitos);
          } catch (e) {
            log('Migration error for historicoTarefasHabitos: $e');
          }
          try {
            await m.createTable(contas);
          } catch (e) {
            log('Migration error for contas: $e');
          }
          try {
            await m.createTable(contatos);
          } catch (e) {
            log('Migration error for contatos: $e');
          }
          try {
            await m.createTable(categoriaTransacoes);
          } catch (e) {
            log('Migration error for categoriaTransacoes: $e');
          }
          try {
            await m.createTable(transacaos);
          } catch (e) {
            log('Migration error for transacaos: $e');
          }
        }
        if (from < 4) {
          try {
            await m.addColumn(categoriaTransacoes, categoriaTransacoes.icone);
          } catch (e) {
            log('Migration error adding icone to categoriaTransacoes: $e');
          }
        }
      },
      beforeOpen: (details) async {
        try {
          await customStatement(
            'ALTER TABLE categoria_transacoes ADD COLUMN icone TEXT;',
          );
        } catch (_) {}
      },
    );
  }

  Future<String?> getSetting(String key) async {
    final query = select(appSettings)..where((s) => s.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    final query = select(appSettings)..where((s) => s.key.equals(key));
    final existing = await query.getSingleOrNull();
    if (existing != null) {
      final updateQuery = update(appSettings)..where((s) => s.key.equals(key));
      await updateQuery.write(AppSettingsCompanion(value: Value(value)));
    } else {
      await into(appSettings).insert(
        AppSettingsCompanion.insert(key: key, value: value),
      );
    }
  }

  Future<void> deleteSetting(String key) async {
    final query = delete(appSettings)..where((s) => s.key.equals(key));
    await query.go();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ppv_digital_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
