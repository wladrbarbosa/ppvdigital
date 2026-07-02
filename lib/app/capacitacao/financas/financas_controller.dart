import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';

class FinancasController {
  FinancasController() {
    init();
  }

  late final Databases databases;

  DateTime _lastSelectedMonth = DateTime.now();
  DateTime get lastSelectedMonth => _lastSelectedMonth;

  final mobx.ObservableList<ContaModel> _contasList =
      mobx.ObservableList<ContaModel>(name: 'contasList');
  List<ContaModel> get contasList => _contasList.toList();

  final mobx.ObservableList<CategoriaTransacaoModel> _categoriasList =
      mobx.ObservableList<CategoriaTransacaoModel>(name: 'categoriasList');
  List<CategoriaTransacaoModel> get categoriasList => _categoriasList.toList();

  final mobx.ObservableList<ContatoModel> _Core.tableContatosList =
      mobx.ObservableList<ContatoModel>(name: 'Core.tableContatosList');
  List<ContatoModel> get Core.tableContatosList => _Core.tableContatosList.toList();

  final mobx.ObservableList<TransacaoModel> _transacoesList =
      mobx.ObservableList<TransacaoModel>(name: 'transacoesList');
  List<TransacaoModel> get transacoesList => _transacoesList.toList();

  final mobx.ObservableList<DivisaoTransacaoModel> _divisoesList =
      mobx.ObservableList<DivisaoTransacaoModel>(name: 'divisoesList');
  List<DivisaoTransacaoModel> get divisoesList => _divisoesList.toList();

  static Future<void>? financasFuture;
  static DateTime? defaultDataCompetencia;

  void init() {
    databases = Databases(Core.client);
  }

  Future<bool> loadDocuments({DateTime? selectedMonth}) async {
    final DateTime targetMonth = selectedMonth ?? _lastSelectedMonth;
    _lastSelectedMonth = targetMonth;

    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }
        final String user = Core.loginController.currentUser?.$id ?? '';
        final TablesDB tablesDB = TablesDB(databases.client);

        // 0. Load Core.tableContatos
        final Core.tableContatosDocs = await tablesDB.listRows(
          databaseId: 'Core.databaseId',
          tableId: 'Core.tableContatos',
          queries: [
            Query.equal('ownerId', [user]),
            Query.limit(5000),
          ],
        );
        _Core.tableContatosList.clear();
        _Core.tableContatosList.addAll(
          Core.tableContatosDocs.rows.map((d) => ContatoModel.fromMap(d.data)),
        );

        final List<String> userContatoIds = _Core.tableContatosList
            .map((c) => c.id)
            .toList();

        // 1. Load accounts
        final accountsDocs = await tablesDB.listRows(
          databaseId: 'Core.databaseId',
          tableId: 'Core.tableContas', // contas
          queries: [
            Query.equal('userId', [user]),
          ],
        );
        _contasList.clear();
        _contasList.addAll(
          accountsDocs.rows.map((d) => ContaModel.fromMap(d.data)),
        );

        // 2. Load categories
        final catDocs = await tablesDB.listRows(
          databaseId: 'Core.databaseId',
          tableId: 'Core.tableCategoriasTransacoes',
          queries: [
            Query.equal('userId', [user]),
          ],
        );
        _categoriasList.clear();
        _categoriasList.addAll(
          catDocs.rows.map((d) => CategoriaTransacaoModel.fromMap(d.data)),
        );

        // 3. Load transactions (for targetMonth)
        final List<String> contaIds = contasList.map((c) => c.id).toList();
        final List<TransacaoModel> loadedTrans = [];
        final List<TransacaoModel> loadedPastTrans = [];

        final firstDayOfMonth = DateTime(
          targetMonth.year,
          targetMonth.month,
          1,
        );
        final lastDayOfMonth = DateTime(
          targetMonth.year,
          targetMonth.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));

        if (contaIds.isNotEmpty) {
          // Query transactions where conta is one of the user's accounts inside selected month
          for (int k = 0; k < contaIds.length; k += 100) {
            final chunkContaIds = contaIds.sublist(
              k,
              k + 100 > contaIds.length ? contaIds.length : k + 100,
            );
            final transDocs1 = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableTransacoes', // transacoes
              queries: [
                Query.equal('conta', chunkContaIds),
                Query.greaterThanEqual(
                  'dataCompetencia',
                  firstDayOfMonth.toIso8601String(),
                ),
                Query.lessThanEqual(
                  'dataCompetencia',
                  lastDayOfMonth.toIso8601String(),
                ),
                Query.select([
                  '*',
                  'conta.*',
                  'contaDestino.*',
                  'categoria.*',
                  'recorrencia.*',
                  'devedorContato.*',
                  'credorContato.*',
                ]),
                Query.limit(5000),
              ],
            );
            for (final doc in transDocs1.rows) {
              final map = Map<String, dynamic>.from(doc.data);
              map['\$id'] = doc.$id;
              loadedTrans.add(TransacaoModel.fromMap(map));
            }
          }

          // Query transactions where contaDestino is one of the user's accounts inside selected month
          for (int k = 0; k < contaIds.length; k += 100) {
            final chunkContaIds = contaIds.sublist(
              k,
              k + 100 > contaIds.length ? contaIds.length : k + 100,
            );
            final transDocs2 = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableTransacoes',
              queries: [
                Query.equal('contaDestino', chunkContaIds),
                Query.greaterThanEqual(
                  'dataCompetencia',
                  firstDayOfMonth.toIso8601String(),
                ),
                Query.lessThanEqual(
                  'dataCompetencia',
                  lastDayOfMonth.toIso8601String(),
                ),
                Query.select([
                  '*',
                  'conta.*',
                  'contaDestino.*',
                  'categoria.*',
                  'recorrencia.*',
                  'devedorContato.*',
                  'credorContato.*',
                ]),
                Query.limit(5000),
              ],
            );
            for (final doc in transDocs2.rows) {
              if (!loadedTrans.any((t) => t.id == doc.$id)) {
                final map = Map<String, dynamic>.from(doc.data);
                map['\$id'] = doc.$id;
                loadedTrans.add(TransacaoModel.fromMap(map));
              }
            }
          }

          // Query past transactions (before selected month) with lightweight select
          for (int k = 0; k < contaIds.length; k += 100) {
            final chunkContaIds = contaIds.sublist(
              k,
              k + 100 > contaIds.length ? contaIds.length : k + 100,
            );
            final transDocs1 = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableTransacoes',
              queries: [
                Query.equal('conta', chunkContaIds),
                Query.lessThan(
                  'dataCompetencia',
                  firstDayOfMonth.toIso8601String(),
                ),
                Query.select([
                  'valor',
                  'tipo',
                  'conta.*',
                  'contaDestino.*',
                  'consolidada',
                  'dataCompetencia',
                ]),
                Query.limit(5000),
              ],
            );
            for (final doc in transDocs1.rows) {
              final map = Map<String, dynamic>.from(doc.data);
              map['\$id'] = doc.$id;
              if (map['conta'] is String) {
                final String cId = map['conta'] as String;
                final contaMatch = contasList.firstWhere(
                  (c) => c.id == cId,
                  orElse: () =>
                      ContaModel(id: cId, name: '', userId: '', saldoAtual: 0),
                );
                map['conta'] = contaMatch.toMap();
              }
              if (map['contaDestino'] is String) {
                final String cId = map['contaDestino'] as String;
                final contaMatch = contasList.firstWhere(
                  (c) => c.id == cId,
                  orElse: () =>
                      ContaModel(id: cId, name: '', userId: '', saldoAtual: 0),
                );
                map['contaDestino'] = contaMatch.toMap();
              }
              loadedPastTrans.add(TransacaoModel.fromMap(map));
            }
          }

          for (int k = 0; k < contaIds.length; k += 100) {
            final chunkContaIds = contaIds.sublist(
              k,
              k + 100 > contaIds.length ? contaIds.length : k + 100,
            );
            final transDocs2 = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableTransacoes',
              queries: [
                Query.equal('contaDestino', chunkContaIds),
                Query.lessThan(
                  'dataCompetencia',
                  firstDayOfMonth.toIso8601String(),
                ),
                Query.select([
                  'valor',
                  'tipo',
                  'conta.*',
                  'contaDestino.*',
                  'consolidada',
                  'dataCompetencia',
                ]),
                Query.limit(5000),
              ],
            );
            for (final doc in transDocs2.rows) {
              if (!loadedPastTrans.any((t) => t.id == doc.$id)) {
                final map = Map<String, dynamic>.from(doc.data);
                map['\$id'] = doc.$id;
                if (map['conta'] is String) {
                  final String cId = map['conta'] as String;
                  final contaMatch = contasList.firstWhere(
                    (c) => c.id == cId,
                    orElse: () => ContaModel(
                      id: cId,
                      name: '',
                      userId: '',
                      saldoAtual: 0,
                    ),
                  );
                  map['conta'] = contaMatch.toMap();
                }
                if (map['contaDestino'] is String) {
                  final String cId = map['contaDestino'] as String;
                  final contaMatch = contasList.firstWhere(
                    (c) => c.id == cId,
                    orElse: () => ContaModel(
                      id: cId,
                      name: '',
                      userId: '',
                      saldoAtual: 0,
                    ),
                  );
                  map['contaDestino'] = contaMatch.toMap();
                }
                loadedPastTrans.add(TransacaoModel.fromMap(map));
              }
            }
          }
        }

        // Query divisions where user's contacts participate
        _divisoesList.clear();
        if (userContatoIds.isNotEmpty) {
          for (int k = 0; k < userContatoIds.length; k += 100) {
            final chunkIds = userContatoIds.sublist(
              k,
              k + 100 > userContatoIds.length ? userContatoIds.length : k + 100,
            );
            final divDocs = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableDivisaoTransacoes',
              queries: [
                Query.equal('contatoResponsavel', chunkIds),
                Query.select([
                  '*',
                  'transacao.*',
                  'transacao.conta.*',
                  'transacao.contaDestino.*',
                  'transacao.categoria.*',
                  'transacao.recorrencia.*',
                  'transacao.devedorContato.*',
                  'transacao.credorContato.*',
                ]),
                Query.limit(5000),
              ],
            );
            _divisoesList.addAll(
              divDocs.rows.map((d) => DivisaoTransacaoModel.fromMap(d.data)),
            );
          }
        }

        // Fetch divisions for loaded current month transactions
        if (loadedTrans.isNotEmpty) {
          final List<String> loadedTransIds = loadedTrans
              .map((t) => t.id)
              .toList();
          final List<DivisaoTransacaoModel> allDivs = [];
          for (int k = 0; k < loadedTransIds.length; k += 100) {
            final chunkIds = loadedTransIds.sublist(
              k,
              k + 100 > loadedTransIds.length ? loadedTransIds.length : k + 100,
            );
            final allDivsDocs = await tablesDB.listRows(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableDivisaoTransacoes',
              queries: [Query.equal('transacao', chunkIds), Query.limit(5000)],
            );
            allDivs.addAll(
              allDivsDocs.rows.map(
                (d) => DivisaoTransacaoModel.fromMap(d.data),
              ),
            );
          }

          for (int i = 0; i < loadedTrans.length; i++) {
            final t = loadedTrans[i];
            final divsForT = allDivs
                .where((d) => d.transacaoId == t.id)
                .toList();
            loadedTrans[i] = t.copyWith(divisoes: divsForT);
          }
        }

        // Bind in-memory divisions to past transactions
        for (int i = 0; i < loadedPastTrans.length; i++) {
          final t = loadedPastTrans[i];
          final divsForT = _divisoesList
              .where((d) => d.transacaoId == t.id)
              .toList();
          loadedPastTrans[i] = t.copyWith(divisoes: divsForT);
        }

        _transacoesList.clear();
        _transacoesList.addAll(loadedTrans);
        _transacoesList.addAll(loadedPastTrans);

        return true;
      } catch (e) {
        log('Error loading finances: $e');
        return false;
      }
    }, name: 'loadDocuments');
  }

  Future<void> updateAccountBalance(String contaId, double amountDiff) async {
    final TablesDB tablesDB = TablesDB(databases.client);
    final account = contasList.firstWhere((c) => c.id == contaId);
    final double newSaldo = account.saldoAtual + amountDiff;
    await tablesDB.updateRow(
      databaseId: 'Core.databaseId',
      tableId: 'Core.tableContas', // contas
      rowId: contaId,
      data: {'saldoAtual': newSaldo},
    );
  }

  Future<bool> createConta(String name, double saldoInicial) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      await tablesDB.createRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContas', // contas
        rowId: ID.unique(),
        data: {'name': name, 'userId': user, 'saldoAtual': saldoInicial},
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating account: $e');
      return false;
    }
  }

  Future<bool> updateConta(String id, String name, double saldoAtual) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.updateRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContas', // contas
        rowId: id,
        data: {'name': name, 'saldoAtual': saldoAtual},
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating account: $e');
      return false;
    }
  }

  Future<bool> deleteConta(String id) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.deleteRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContas', // contas
        rowId: id,
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting account: $e');
      return false;
    }
  }

  Future<bool> createCategoria(
    String name,
    String? icone,
    String hexColor,
  ) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      await tablesDB.createRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableCategoriasTransacoes',
        rowId: ID.unique(),
        data: {'userId': user, 'name': name, 'icone': icone, 'cor': hexColor},
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating category: $e');
      return false;
    }
  }

  Future<bool> updateCategoria(
    String id,
    String name,
    String? icone,
    String hexColor,
  ) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.updateRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableCategoriasTransacoes',
        rowId: id,
        data: {'name': name, 'icone': icone, 'cor': hexColor},
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategoria(String id) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.deleteRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableCategoriasTransacoes',
        rowId: id,
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting category: $e');
      return false;
    }
  }

  Future<bool> createTransacao({
    required String descricao,
    required double valor,
    required String tipo,
    required DateTime dataCompetencia,
    required String? contaId,
    required String? contaDestinoId,
    required bool consolidada,
    required String? categoriaId,
    required bool recorrente,
    bool recorrenciaIndeterminada = false,
    String tipoRecorrencia = 'mês',
    int frequencia = 1,
    int totalParcelas = 1,
    int parcelaInicio = 1,
    DateTime? fimRecorrencia,
    List<Map<String, dynamic>> divisao =
        const [], // List of {contatoResponsavel, peso}
    String? devedorContatoId,
    String? credorContatoId,
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      String? recId;

      if (recorrente) {
        final Row recRow = await tablesDB.createRow(
          databaseId: 'Core.databaseId',
          tableId: 'Core.tableTransacaoRecorrencias',
          rowId: ID.unique(),
          data: {
            'tipoRecorrencia': tipoRecorrencia,
            'frequencia': frequencia,
            'totalParcelas': recorrenciaIndeterminada ? null : totalParcelas,
            'parcelaInicio': recorrenciaIndeterminada ? null : parcelaInicio,
            'fimRecorrencia': fimRecorrencia?.toIso8601String(),
          },
        );
        recId = recRow.$id;
      }

      final int remainingParcels = totalParcelas - parcelaInicio + 1;
      final int loopLimit = recorrente
          ? (recorrenciaIndeterminada ? 24 : remainingParcels)
          : 1;

      if (recorrente) {
        final List<Map<String, dynamic>> ops = [];

        for (int i = 1; i <= loopLimit; i++) {
          DateTime date = dataCompetencia;
          if (tipoRecorrencia == 'dia') {
            date = dataCompetencia.add(Duration(days: (i - 1) * frequencia));
          } else if (tipoRecorrencia == 'semana') {
            date = dataCompetencia.add(
              Duration(days: (i - 1) * 7 * frequencia),
            );
          } else if (tipoRecorrencia == 'mês') {
            date = DateTime(
              dataCompetencia.year,
              dataCompetencia.month + (i - 1) * frequencia,
              dataCompetencia.day,
              dataCompetencia.hour,
              dataCompetencia.minute,
            );
          } else if (tipoRecorrencia == 'ano') {
            date = DateTime(
              dataCompetencia.year + (i - 1) * frequencia,
              dataCompetencia.month,
              dataCompetencia.day,
              dataCompetencia.hour,
              dataCompetencia.minute,
            );
          }

          final String descFinal = recorrente && !recorrenciaIndeterminada
              ? '$descricao (Parcela ${parcelaInicio + i - 1}/$totalParcelas)'
              : descricao;

          final String tRowId = ID.unique();

          // Stage transaction creation
          ops.add({
            'action': 'create',
            'databaseId': 'Core.databaseId',
            'tableId': 'Core.tableTransacoes',
            'rowId': tRowId,
            'data': {
              'descricao': descFinal,
              'valor': valor,
              'tipo': tipo,
              'dataCompetencia': date.toIso8601String(),
              'conta': contaId,
              'contaDestino': contaDestinoId,
              'consolidada': consolidada,
              'categoria': categoriaId,
              'recorrencia': recId,
              'devedorContato': devedorContatoId,
              'credorContato': credorContatoId,
            },
          });

          // Adjust account balance if consolidated
          if (consolidada) {
            if (tipo == 'despesa' && contaId != null) {
              await updateAccountBalance(contaId, -valor);
            } else if (tipo == 'receita' && contaId != null) {
              await updateAccountBalance(contaId, valor);
            } else if (tipo == 'transferencia' &&
                contaId != null &&
                contaDestinoId != null) {
              await updateAccountBalance(contaId, -valor);
              await updateAccountBalance(contaDestinoId, valor);
            }
          }

          // Stage division creation
          for (final divItem in divisao) {
            final String rContato = divItem['contatoResponsavel'] as String;
            final double rPeso = (divItem['peso'] as num).toDouble();
            ops.add({
              'action': 'create',
              'databaseId': 'Core.databaseId',
              'tableId': 'Core.tableDivisaoTransacoes',
              'rowId': ID.unique(),
              'data': {
                'transacao': tRowId,
                'contatoResponsavel': rContato,
                'peso': rPeso,
              },
            });
          }
        }

        // Send operations in blocks of 100, each inside its own transaction
        for (int j = 0; j < ops.length; j += 100) {
          final chunk = ops.sublist(
            j,
            j + 100 > ops.length ? ops.length : j + 100,
          );
          final String txId = (await tablesDB.createTransaction()).$id;
          await tablesDB.createOperations(
            transactionId: txId,
            operations: chunk,
          );
          await tablesDB.updateTransaction(transactionId: txId, commit: true);
        }
      } else {
        // Single non-recurrent transaction (normal flow)
        final String tRowId = ID.unique();
        await tablesDB.createRow(
          databaseId: 'Core.databaseId',
          tableId: 'Core.tableTransacoes',
          rowId: tRowId,
          data: {
            'descricao': descricao,
            'valor': valor,
            'tipo': tipo,
            'dataCompetencia': dataCompetencia.toIso8601String(),
            'conta': contaId,
            'contaDestino': contaDestinoId,
            'consolidada': consolidada,
            'categoria': categoriaId,
            'devedorContato': devedorContatoId,
            'credorContato': credorContatoId,
          },
        );

        if (consolidada) {
          if (tipo == 'despesa' && contaId != null) {
            await updateAccountBalance(contaId, -valor);
          } else if (tipo == 'receita' && contaId != null) {
            await updateAccountBalance(contaId, valor);
          } else if (tipo == 'transferencia' &&
              contaId != null &&
              contaDestinoId != null) {
            await updateAccountBalance(contaId, -valor);
            await updateAccountBalance(contaDestinoId, valor);
          }
        }

        for (final divItem in divisao) {
          final String rContato = divItem['contatoResponsavel'] as String;
          final double rPeso = (divItem['peso'] as num).toDouble();
          await tablesDB.createRow(
            databaseId: 'Core.databaseId',
            tableId: 'Core.tableDivisaoTransacoes',
            rowId: ID.unique(),
            data: {
              'transacao': tRowId,
              'contatoResponsavel': rContato,
              'peso': rPeso,
            },
          );
        }
      }

      FinancasController.defaultDataCompetencia = dataCompetencia;
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransacao({
    required String id,
    required String descricao,
    required double valor,
    required String tipo,
    required DateTime dataCompetencia,
    required String? contaId,
    required String? contaDestinoId,
    required bool consolidada,
    required String? categoriaId,
    required List<Map<String, dynamic>>
    divisao, // List of {contatoResponsavel, peso}
    String? optionRecorrencia, // 'only_current', 'current_and_future', 'all'
    String? devedorContatoId,
    String? credorContatoId,
    int? parcelaInicio,
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      final List<Map<String, dynamic>> ops = [];

      // Find original transaction to check if consolidated state or amount changed
      final original = transacoesList.firstWhere((t) => t.id == id);

      // 1. Revert original balance effects if it was consolidated
      if (original.consolidada) {
        if (original.tipo == 'despesa' && original.conta != null) {
          await updateAccountBalance(original.conta!.id, original.valor);
        } else if (original.tipo == 'receita' && original.conta != null) {
          await updateAccountBalance(original.conta!.id, -original.valor);
        } else if (original.tipo == 'transferencia' &&
            original.conta != null &&
            original.contaDestino != null) {
          await updateAccountBalance(original.conta!.id, original.valor);
          await updateAccountBalance(
            original.contaDestino!.id,
            -original.valor,
          );
        }
      }

      final delta = dataCompetencia.difference(original.dataCompetencia);
      String? updatedRecId = original.recorrencia?.id;

      if (original.recorrencia != null && optionRecorrencia != null) {
        if (optionRecorrencia == 'only_current') {
          updatedRecId = null;
        } else if (optionRecorrencia == 'current_and_future') {
          // create new recurrence row
          final originalRec = original.recorrencia!;
          final Row newRecRow = await tablesDB.createRow(
            databaseId: 'Core.databaseId',
            tableId: 'Core.tableTransacaoRecorrencias',
            rowId: ID.unique(),
            data: {
              'tipoRecorrencia': originalRec.tipoRecorrencia,
              'frequencia': originalRec.frequencia,
              'totalParcelas': originalRec.totalParcelas,
              'parcelaInicio': parcelaInicio ?? originalRec.parcelaInicio,
              'fimRecorrencia': originalRec.fimRecorrencia?.toIso8601String(),
            },
          );
          updatedRecId = newRecRow.$id;

          // update other future transactions in series
          final allRecTrans = transacoesList
              .where((t) => t.recorrencia?.id == original.recorrencia!.id)
              .toList();
          final futureTrans = allRecTrans
              .where(
                (t) =>
                    t.id != original.id &&
                    t.dataCompetencia.isAfter(original.dataCompetencia),
              )
              .toList();

          for (final t in futureTrans) {
            // Revert balance if consolidated
            if (t.consolidada) {
              if (t.tipo == 'despesa' && t.conta != null) {
                await updateAccountBalance(t.conta!.id, t.valor);
              } else if (t.tipo == 'receita' && t.conta != null) {
                await updateAccountBalance(t.conta!.id, -t.valor);
              } else if (t.tipo == 'transferencia' &&
                  t.conta != null &&
                  t.contaDestino != null) {
                await updateAccountBalance(t.conta!.id, t.valor);
                await updateAccountBalance(t.contaDestino!.id, -t.valor);
              }
            }

            final newDate = t.dataCompetencia.add(delta);

            // Stage transaction update
            ops.add({
              'action': 'update',
              'databaseId': 'Core.databaseId',
              'tableId': 'Core.tableTransacoes',
              'rowId': t.id,
              'data': {
                'descricao': descricao,
                'valor': valor,
                'tipo': tipo,
                'dataCompetencia': newDate.toIso8601String(),
                'conta': contaId,
                'contaDestino': contaDestinoId,
                'consolidada': consolidada,
                'categoria': categoriaId,
                'recorrencia': updatedRecId,
                'devedorContato': devedorContatoId,
                'credorContato': credorContatoId,
              },
            });

            // Apply new balance
            if (consolidada) {
              if (tipo == 'despesa' && contaId != null) {
                await updateAccountBalance(contaId, -valor);
              } else if (tipo == 'receita' && contaId != null) {
                await updateAccountBalance(contaId, valor);
              } else if (tipo == 'transferencia' &&
                  contaId != null &&
                  contaDestinoId != null) {
                await updateAccountBalance(contaId, -valor);
                await updateAccountBalance(contaDestinoId, valor);
              }
            }

            // Stage division deletes
            for (final oldDiv in t.divisoes) {
              ops.add({
                'action': 'delete',
                'databaseId': 'Core.databaseId',
                'tableId': 'Core.tableDivisaoTransacoes',
                'rowId': oldDiv.id,
              });
            }
            // Stage division creates
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              final double rPeso = (divItem['peso'] as num).toDouble();
              ops.add({
                'action': 'create',
                'databaseId': 'Core.databaseId',
                'tableId': 'Core.tableDivisaoTransacoes',
                'rowId': ID.unique(),
                'data': {
                  'transacao': t.id,
                  'contatoResponsavel': rContato,
                  'peso': rPeso,
                },
              });
            }
          }
        } else if (optionRecorrencia == 'all') {
          if (parcelaInicio != null) {
            await tablesDB.updateRow(
              databaseId: 'Core.databaseId',
              tableId: 'Core.tableTransacaoRecorrencias',
              rowId: original.recorrencia!.id,
              data: {'parcelaInicio': parcelaInicio},
            );
          }
          // update all other transactions in series
          final allRecTrans = transacoesList
              .where((t) => t.recorrencia?.id == original.recorrencia!.id)
              .toList();
          final otherTrans = allRecTrans
              .where((t) => t.id != original.id)
              .toList();

          for (final t in otherTrans) {
            // Revert balance if consolidated
            if (t.consolidada) {
              if (t.tipo == 'despesa' && t.conta != null) {
                await updateAccountBalance(t.conta!.id, t.valor);
              } else if (t.tipo == 'receita' && t.conta != null) {
                await updateAccountBalance(t.conta!.id, -t.valor);
              } else if (t.tipo == 'transferencia' &&
                  t.conta != null &&
                  t.contaDestino != null) {
                await updateAccountBalance(t.conta!.id, t.valor);
                await updateAccountBalance(t.contaDestino!.id, -t.valor);
              }
            }

            final newDate = t.dataCompetencia.add(delta);

            // Stage transaction update
            ops.add({
              'action': 'update',
              'databaseId': 'Core.databaseId',
              'tableId': 'Core.tableTransacoes',
              'rowId': t.id,
              'data': {
                'descricao': descricao,
                'valor': valor,
                'tipo': tipo,
                'dataCompetencia': newDate.toIso8601String(),
                'conta': contaId,
                'contaDestino': contaDestinoId,
                'consolidada': consolidada,
                'categoria': categoriaId,
                'devedorContato': devedorContatoId,
                'credorContato': credorContatoId,
              },
            });

            // Apply new balance
            if (consolidada) {
              if (tipo == 'despesa' && contaId != null) {
                await updateAccountBalance(contaId, -valor);
              } else if (tipo == 'receita' && contaId != null) {
                await updateAccountBalance(contaId, valor);
              } else if (tipo == 'transferencia' &&
                  contaId != null &&
                  contaDestinoId != null) {
                await updateAccountBalance(contaId, -valor);
                await updateAccountBalance(contaDestinoId, valor);
              }
            }

            // Stage division deletes
            for (final oldDiv in t.divisoes) {
              ops.add({
                'action': 'delete',
                'databaseId': 'Core.databaseId',
                'tableId': 'Core.tableDivisaoTransacoes',
                'rowId': oldDiv.id,
              });
            }
            // Stage division creates
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              final double rPeso = (divItem['peso'] as num).toDouble();
              ops.add({
                'action': 'create',
                'databaseId': 'Core.databaseId',
                'tableId': 'Core.tableDivisaoTransacoes',
                'rowId': ID.unique(),
                'data': {
                  'transacao': t.id,
                  'contatoResponsavel': rContato,
                  'peso': rPeso,
                },
              });
            }
          }
        }
      }

      // 2. Stage current transaction update
      ops.add({
        'action': 'update',
        'databaseId': 'Core.databaseId',
        'tableId': 'Core.tableTransacoes', // transacoes
        'rowId': id,
        'data': {
          'descricao': descricao,
          'valor': valor,
          'tipo': tipo,
          'dataCompetencia': dataCompetencia.toIso8601String(),
          'conta': contaId,
          'contaDestino': contaDestinoId,
          'consolidada': consolidada,
          'categoria': categoriaId,
          'recorrencia': updatedRecId,
          'devedorContato': devedorContatoId,
          'credorContato': credorContatoId,
        },
      });

      // Apply new balance effects if consolidated
      if (consolidada) {
        if (tipo == 'despesa' && contaId != null) {
          await updateAccountBalance(contaId, -valor);
        } else if (tipo == 'receita' && contaId != null) {
          await updateAccountBalance(contaId, valor);
        } else if (tipo == 'transferencia' &&
            contaId != null &&
            contaDestinoId != null) {
          await updateAccountBalance(contaId, -valor);
          await updateAccountBalance(contaDestinoId, valor);
        }
      }

      // 4. Stage division rows (delete old and write new)
      for (final oldDiv in original.divisoes) {
        ops.add({
          'action': 'delete',
          'databaseId': 'Core.databaseId',
          'tableId': 'Core.tableDivisaoTransacoes',
          'rowId': oldDiv.id,
        });
      }

      for (final divItem in divisao) {
        final String rContato = divItem['contatoResponsavel'] as String;
        final double rPeso = (divItem['peso'] as num).toDouble();
        ops.add({
          'action': 'create',
          'databaseId': 'Core.databaseId',
          'tableId': 'Core.tableDivisaoTransacoes',
          'rowId': ID.unique(),
          'data': {
            'transacao': id,
            'contatoResponsavel': rContato,
            'peso': rPeso,
          },
        });
      }

      // Execute all operations in batches of 100, each inside its own transaction
      for (int j = 0; j < ops.length; j += 100) {
        final chunk = ops.sublist(
          j,
          j + 100 > ops.length ? ops.length : j + 100,
        );
        final String txId = (await tablesDB.createTransaction()).$id;
        await tablesDB.createOperations(transactionId: txId, operations: chunk);
        await tablesDB.updateTransaction(transactionId: txId, commit: true);
      }

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> batchUpdateTransactions({
    required List<String> transIds,
    required String action, // 'consolidar' | 'dataCompetencia' | 'conta'
    required dynamic newValue, // bool | DateTime | String
    required String
    recurrenceOption, // 'only_current' | 'current_and_future' | 'all'
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      final List<Map<String, dynamic>> ops = [];
      final List<TransacaoModel> targetTransactions = [];

      for (final id in transIds) {
        final matches = transacoesList.where((t) => t.id == id);
        if (matches.isEmpty) continue;
        final original = matches.first;

        List<TransacaoModel> seriesToUpdate = [];
        if (original.recorrencia != null &&
            recurrenceOption != 'only_current') {
          final allRecTrans = transacoesList
              .where((t) => t.recorrencia?.id == original.recorrencia!.id)
              .toList();

          if (recurrenceOption == 'all') {
            seriesToUpdate = allRecTrans;
          } else if (recurrenceOption == 'current_and_future') {
            seriesToUpdate = allRecTrans
                .where(
                  (t) =>
                      t.dataCompetencia.isAtSameMomentAs(
                        original.dataCompetencia,
                      ) ||
                      t.dataCompetencia.isAfter(original.dataCompetencia),
                )
                .toList();
          }
        } else {
          seriesToUpdate = [original];
        }

        for (final t in seriesToUpdate) {
          if (!targetTransactions.any((item) => item.id == t.id)) {
            targetTransactions.add(t);
          }
        }
      }

      // Revert account balances for target transactions that are currently consolidated
      for (final t in targetTransactions) {
        if (t.consolidada) {
          if (t.tipo == 'despesa' && t.conta != null) {
            await updateAccountBalance(t.conta!.id, t.valor);
          } else if (t.tipo == 'receita' && t.conta != null) {
            await updateAccountBalance(t.conta!.id, -t.valor);
          } else if (t.tipo == 'transferencia' &&
              t.conta != null &&
              t.contaDestino != null) {
            await updateAccountBalance(t.conta!.id, t.valor);
            await updateAccountBalance(t.contaDestino!.id, -t.valor);
          }
        }
      }

      // Prepare updates
      for (final t in targetTransactions) {
        final Map<String, dynamic> updateData = {};

        if (action == 'consolidar') {
          updateData['consolidada'] = newValue as bool;
        } else if (action == 'dataCompetencia') {
          final DateTime newDate = newValue as DateTime;
          TransacaoModel? originalForT;
          for (final origId in transIds) {
            final matchesOrig = transacoesList.where((o) => o.id == origId);
            if (matchesOrig.isEmpty) continue;
            final orig = matchesOrig.first;
            if (t.recorrencia != null &&
                orig.recorrencia != null &&
                t.recorrencia!.id == orig.recorrencia!.id) {
              originalForT = orig;
              break;
            }
          }
          if (originalForT != null) {
            final delta = newDate.difference(originalForT.dataCompetencia);
            if (t.id == originalForT.id) {
              updateData['dataCompetencia'] = newDate.toIso8601String();
            } else {
              updateData['dataCompetencia'] = t.dataCompetencia
                  .add(delta)
                  .toIso8601String();
            }
          } else {
            updateData['dataCompetencia'] = newDate.toIso8601String();
          }
        } else if (action == 'conta') {
          updateData['conta'] = newValue as String;
        }

        ops.add({
          'action': 'update',
          'databaseId': 'Core.databaseId',
          'tableId': 'Core.tableTransacoes',
          'rowId': t.id,
          'data': updateData,
        });

        final bool nextConsolidada = updateData.containsKey('consolidada')
            ? (updateData['consolidada'] as bool)
            : t.consolidada;
        final String? nextContaId = updateData.containsKey('conta')
            ? (updateData['conta'] as String)
            : t.conta?.id;

        if (nextConsolidada) {
          if (t.tipo == 'despesa' && nextContaId != null) {
            await updateAccountBalance(nextContaId, -t.valor);
          } else if (t.tipo == 'receita' && nextContaId != null) {
            await updateAccountBalance(nextContaId, t.valor);
          } else if (t.tipo == 'transferencia' &&
              nextContaId != null &&
              t.contaDestino?.id != null) {
            await updateAccountBalance(nextContaId, -t.valor);
            await updateAccountBalance(t.contaDestino!.id, t.valor);
          }
        }
      }

      for (int j = 0; j < ops.length; j += 100) {
        final chunk = ops.sublist(
          j,
          j + 100 > ops.length ? ops.length : j + 100,
        );
        final String txId = (await tablesDB.createTransaction()).$id;
        await tablesDB.createOperations(transactionId: txId, operations: chunk);
        await tablesDB.updateTransaction(transactionId: txId, commit: true);
      }

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error during batch update: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction({
    required TransacaoModel transacao,
    required String deleteOption, // 'only_current', 'all', 'current_and_future'
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      List<TransacaoModel> toDelete = [];

      if (deleteOption == 'only_current' || transacao.recorrencia == null) {
        toDelete = [transacao];
      } else {
        final recId = transacao.recorrencia!.id;
        final allRecTrans = transacoesList
            .where((t) => t.recorrencia?.id == recId)
            .toList();

        if (deleteOption == 'all') {
          toDelete = allRecTrans;
        } else if (deleteOption == 'current_and_future') {
          toDelete = allRecTrans
              .where(
                (t) =>
                    t.dataCompetencia.isAtSameMomentAs(
                      transacao.dataCompetencia,
                    ) ||
                    t.dataCompetencia.isAfter(transacao.dataCompetencia),
              )
              .toList();
        }
      }

      final List<Map<String, dynamic>> ops = [];

      for (final t in toDelete) {
        // Delete all division records
        for (final div in t.divisoes) {
          ops.add({
            'action': 'delete',
            'databaseId': 'Core.databaseId',
            'tableId': 'Core.tableDivisaoTransacoes',
            'rowId': div.id,
          });
        }

        // Adjust balance back if it was consolidated
        if (t.consolidada) {
          if (t.tipo == 'despesa' && t.conta != null) {
            await updateAccountBalance(t.conta!.id, t.valor);
          } else if (t.tipo == 'receita' && t.conta != null) {
            await updateAccountBalance(t.conta!.id, -t.valor);
          } else if (t.tipo == 'transferencia' &&
              t.conta != null &&
              t.contaDestino != null) {
            await updateAccountBalance(t.conta!.id, t.valor);
            await updateAccountBalance(t.contaDestino!.id, -t.valor);
          }
        }

        // Stage the transaction itself
        ops.add({
          'action': 'delete',
          'databaseId': 'Core.databaseId',
          'tableId': 'Core.tableTransacoes', // transacoes
          'rowId': t.id,
        });
      }

      if (transacao.recorrencia != null && deleteOption == 'all') {
        ops.add({
          'action': 'delete',
          'databaseId': 'Core.databaseId',
          'tableId': 'Core.tableTransacaoRecorrencias',
          'rowId': transacao.recorrencia!.id,
        });
      }

      // Execute all operations in batches of 100, each inside its own transaction
      for (int j = 0; j < ops.length; j += 100) {
        final chunk = ops.sublist(
          j,
          j + 100 > ops.length ? ops.length : j + 100,
        );
        final String txId = (await tablesDB.createTransaction()).$id;
        await tablesDB.createOperations(transactionId: txId, operations: chunk);
        await tablesDB.updateTransaction(transactionId: txId, commit: true);
      }

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> createContato({
    required String nome,
    String? telefone,
    String? email,
    String? userId,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      await tablesDB.createRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContatos',
        rowId: ID.unique(),
        data: {
          'ownerId': user,
          'nome': nome,
          'telefone': telefone,
          'email': email,
          'userId': userId,
        },
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error creating contact: $e');
      return false;
    }
  }

  Future<bool> updateContato({
    required String id,
    required String nome,
    String? telefone,
    String? email,
    String? userId,
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.updateRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContatos',
        rowId: id,
        data: {
          'nome': nome,
          'telefone': telefone,
          'email': email,
          'userId': userId,
        },
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating contact: $e');
      return false;
    }
  }

  Future<bool> deleteContato(String id) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.deleteRow(
        databaseId: 'Core.databaseId',
        tableId: 'Core.tableContatos',
        rowId: id,
      );
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting contact: $e');
      return false;
    }
  }
}
