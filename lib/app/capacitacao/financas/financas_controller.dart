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

  final mobx.ObservableList<ContatoModel> _contatosList =
      mobx.ObservableList<ContatoModel>(name: 'contatosList');
  List<ContatoModel> get contatosList => _contatosList.toList();

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
        final contatosDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableContatos,
          queries: [
            Query.equal('ownerId', [user]),
            Query.limit(5000),
          ],
        );
        _contatosList.clear();
        _contatosList.addAll(
          contatosDocs.rows.map((d) => ContatoModel.fromMap(d.data)),
        );

        // Auto-create a contact for the current user if they don't have one
        final bool hasUserContato = _contatosList.any((c) => c.userId == user);
        if (!hasUserContato && user.isNotEmpty) {
          final String currentUserName = Core.loginController.currentUser?.name ?? 'Eu';
          final String currentUserEmail = Core.loginController.currentUser?.email ?? '';
          try {
            final Row newContactRow = await tablesDB.createRow(
              databaseId: Core.databaseId,
              tableId: Core.tableContatos,
              rowId: ID.unique(),
              data: {
                'ownerId': user,
                'nome': currentUserName.isNotEmpty ? '$currentUserName (Eu)' : 'Eu',
                'email': currentUserEmail.isNotEmpty ? currentUserEmail : null,
                'userId': user,
              },
            );
            final map = Map<String, dynamic>.from(newContactRow.data);
            map['\$id'] = newContactRow.$id;
            _contatosList.add(ContatoModel.fromMap(map));
          } catch (e) {
            log('Error auto-creating user contact: $e');
          }
        }

        final List<String> userContatoIds = _contatosList
            .map((c) => c.id)
            .toList();

        // 1. Load accounts
        final accountsDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableContas, // contas
          queries: [
            Query.equal('userId', [user]),
            Query.limit(5000),
          ],
        );
        _contasList.clear();
        _contasList.addAll(
          accountsDocs.rows.map((d) => ContaModel.fromMap(d.data)),
        );

        // 2. Load categories
        final catDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableCategoriasTransacoes,
          queries: [
            Query.equal('userId', [user]),
            Query.limit(5000),
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
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes, // transacoes
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
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes,
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
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes,
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
                  'categoria.*',
                  'devedorContato.*',
                  'credorContato.*',
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
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes,
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
                  'categoria.*',
                  'devedorContato.*',
                  'credorContato.*',
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

        _divisoesList.clear();
        if (userContatoIds.isNotEmpty) {
          for (int k = 0; k < userContatoIds.length; k += 100) {
            final chunkIds = userContatoIds.sublist(
              k,
              k + 100 > userContatoIds.length ? userContatoIds.length : k + 100,
            );

            int offset = 0;
            const int pageSize = 500;
            while (true) {
              final divDocs = await tablesDB.listRows(
                databaseId: Core.databaseId,
                tableId: Core.tableDivisaoTransacoes,
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
                  Query.limit(pageSize),
                  Query.offset(offset),
                ],
              );

              _divisoesList.addAll(
                divDocs.rows.map((d) => DivisaoTransacaoModel.fromMap(d.data)),
              );

              if (divDocs.rows.length < pageSize) {
                break;
              }
              offset += pageSize;
            }
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
              databaseId: Core.databaseId,
              tableId: Core.tableDivisaoTransacoes,
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
    final int idx = _contasList.indexWhere((c) => c.id == contaId);
    if (idx != -1) {
      final account = _contasList[idx];
      final double newSaldo = account.saldoAtual + amountDiff;
      mobx.runInAction(() {
        _contasList[idx] = account.copyWith(saldoAtual: newSaldo);
      });
      await tablesDB.updateRow(
        databaseId: Core.databaseId,
        tableId: Core.tableContas, // contas
        rowId: contaId,
        data: {'saldoAtual': newSaldo},
      );
    }
  }

  Future<bool> createConta(String name, double saldoInicial) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final TablesDB tablesDB = TablesDB(databases.client);

      await tablesDB.createRow(
        databaseId: Core.databaseId,
        tableId: Core.tableContas, // contas
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
        databaseId: Core.databaseId,
        tableId: Core.tableContas, // contas
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
        databaseId: Core.databaseId,
        tableId: Core.tableContas, // contas
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
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTransacoes,
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
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTransacoes,
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
        databaseId: Core.databaseId,
        tableId: Core.tableCategoriasTransacoes,
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
    String? pagadorRecebedorId,
  }) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';
      final userContato = _contatosList.firstWhere(
        (c) => c.userId == user,
        orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
      );
      final String userContatoId = userContato.id;

      final TablesDB tablesDB = TablesDB(databases.client);
      String? recId;

      if (recorrente) {
        final Row recRow = await tablesDB.createRow(
          databaseId: Core.databaseId,
          tableId: Core.tableTransacaoRecorrencias,
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
            'databaseId': Core.databaseId,
            'tableId': Core.tableTransacoes,
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
              'databaseId': Core.databaseId,
              'tableId': Core.tableDivisaoTransacoes,
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
        final bool isDivision = divisao.length > 1 &&
            pagadorRecebedorId != null &&
            (tipo == 'despesa' || tipo == 'receita');

        if (isDivision) {
          final double totalWeights = divisao.fold(
            0.0,
            (sum, item) => sum + (item['peso'] as num).toDouble(),
          );

          if (pagadorRecebedorId == userContatoId) {
            // Case A: User paid/received.
            // 1. Create main transaction for user (total amount)
            final String tRowId = ID.unique();
            await tablesDB.createRow(
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes,
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

            // Adjust balance for main transaction
            if (consolidada) {
              if (tipo == 'despesa' && contaId != null) {
                await updateAccountBalance(contaId, -valor);
              } else if (tipo == 'receita' && contaId != null) {
                await updateAccountBalance(contaId, valor);
              }
            }

            // Create divisions
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              final double rPeso = (divItem['peso'] as num).toDouble();
              await tablesDB.createRow(
                databaseId: Core.databaseId,
                tableId: Core.tableDivisaoTransacoes,
                rowId: ID.unique(),
                data: {
                  'transacao': tRowId,
                  'contatoResponsavel': rContato,
                  'peso': rPeso,
                },
              );
            }

            // 2. Create refund transactions from other contacts
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              if (rContato == userContatoId) continue;
              final double rPeso = (divItem['peso'] as num).toDouble();
              final double shareValue = valor * (rPeso / totalWeights);

              final String refundType = tipo == 'despesa' ? 'receita' : 'despesa';
              final String? refDevedor = refundType == 'receita' ? rContato : null;
              final String? refCredor = refundType == 'despesa' ? rContato : null;

              await tablesDB.createRow(
                databaseId: Core.databaseId,
                tableId: Core.tableTransacoes,
                rowId: ID.unique(),
                data: {
                  'descricao': 'Reembolso: $descricao',
                  'valor': shareValue,
                  'tipo': refundType,
                  'dataCompetencia': dataCompetencia.toIso8601String(),
                  'conta': contaId,
                  'consolidada': consolidada,
                  'categoria': categoriaId,
                  'devedorContato': refDevedor,
                  'credorContato': refCredor,
                },
              );

              // Adjust balance for refund transaction
              if (consolidada && contaId != null) {
                if (refundType == 'despesa') {
                  await updateAccountBalance(contaId, -shareValue);
                } else {
                  await updateAccountBalance(contaId, shareValue);
                }
              }
            }
          } else {
            // Case B: Another contact paid/received.
            final userDiv = divisao.firstWhere(
              (d) => d['contatoResponsavel'] == userContatoId,
              orElse: () => {},
            );
            final double userWeight = userDiv.isNotEmpty
                ? (userDiv['peso'] as num).toDouble()
                : 0.0;
            final double userShareValue = valor * (userWeight / totalWeights);

            final String? refDevedor = tipo == 'receita' ? pagadorRecebedorId : null;
            final String? refCredor = tipo == 'despesa' ? pagadorRecebedorId : null;

            await tablesDB.createRow(
              databaseId: Core.databaseId,
              tableId: Core.tableTransacoes,
              rowId: ID.unique(),
              data: {
                'descricao': 'Partilha: $descricao',
                'valor': userShareValue,
                'tipo': tipo,
                'dataCompetencia': dataCompetencia.toIso8601String(),
                'conta': contaId,
                'consolidada': consolidada,
                'categoria': categoriaId,
                'devedorContato': refDevedor,
                'credorContato': refCredor,
              },
            );

            // Adjust balance for user's share transaction
            if (consolidada && contaId != null) {
              if (tipo == 'despesa') {
                await updateAccountBalance(contaId, -userShareValue);
              } else if (tipo == 'receita') {
                await updateAccountBalance(contaId, userShareValue);
              }
            }
          }
        } else {
          // Normal single transaction (no division or single division)
          final String tRowId = ID.unique();
          await tablesDB.createRow(
            databaseId: Core.databaseId,
            tableId: Core.tableTransacoes,
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
              databaseId: Core.databaseId,
              tableId: Core.tableDivisaoTransacoes,
              rowId: ID.unique(),
              data: {
                'transacao': tRowId,
                'contatoResponsavel': rContato,
                'peso': rPeso,
              },
            );
          }
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
    String? tipoRecorrencia,
    int? frequencia,
    int? totalParcelas,
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

      // Local helper function to calculate recurrent dates
      DateTime calculateRecurrentDate(DateTime baseDate, String period, int freq, int offset) {
        if (period == 'dia') {
          return baseDate.add(Duration(days: offset * freq));
        } else if (period == 'semana') {
          return baseDate.add(Duration(days: offset * 7 * freq));
        } else if (period == 'mês') {
          return DateTime(
            baseDate.year,
            baseDate.month + offset * freq,
            baseDate.day,
            baseDate.hour,
            baseDate.minute,
          );
        } else if (period == 'ano') {
          return DateTime(
            baseDate.year + offset * freq,
            baseDate.month,
            baseDate.day,
            baseDate.hour,
            baseDate.minute,
          );
        }
        return baseDate;
      }

      String newMainDesc = descricao;

      if (original.recorrencia != null && optionRecorrencia != null) {
        if (optionRecorrencia == 'only_current') {
          updatedRecId = null;
          // Strip any suffix for single edited transaction split off from recurrence
          final match = RegExp(r'^(.*)\s\(Parcela\s\d+/\d+\)$').firstMatch(descricao);
          if (match != null) {
            newMainDesc = match.group(1)!;
          }
        } else {
          final allRecTrans = await _fetchRecurrenceSeries(
            tablesDB,
            original.recorrencia!.id,
          );

          if (optionRecorrencia == 'current_and_future') {
            // create new recurrence row
            final originalRec = original.recorrencia!;
            final Row newRecRow = await tablesDB.createRow(
              databaseId: Core.databaseId,
              tableId: Core.tableTransacaoRecorrencias,
              rowId: ID.unique(),
              data: {
                'tipoRecorrencia': tipoRecorrencia ?? originalRec.tipoRecorrencia,
                'frequencia': frequencia ?? originalRec.frequencia,
                'totalParcelas': totalParcelas,
                'parcelaInicio': parcelaInicio ?? originalRec.parcelaInicio,
                'fimRecorrencia': originalRec.fimRecorrencia?.toIso8601String(),
              },
            );
            updatedRecId = newRecRow.$id;

            // Sort future transactions chronologically
            final futureTrans = allRecTrans
                .where(
                  (t) =>
                      t.id != original.id &&
                      t.dataCompetencia.isAfter(original.dataCompetencia),
                )
                .toList();
            futureTrans.sort((a, b) => a.dataCompetencia.compareTo(b.dataCompetencia));

            final String finalPeriod = tipoRecorrencia ?? originalRec.tipoRecorrencia;
            final int finalFreq = frequencia ?? originalRec.frequencia ?? 1;

            // Rebuild description for the current edited transaction
            String baseDesc = descricao;
            final match = RegExp(r'^(.*)\s\(Parcela\s\d+/\d+\)$').firstMatch(descricao);
            if (match != null) {
              baseDesc = match.group(1)!;
            }
            final int currentParcel = parcelaInicio ?? originalRec.parcelaInicio ?? 1;
            newMainDesc = totalParcelas == null
                ? baseDesc
                : '$baseDesc (Parcela $currentParcel/$totalParcelas)';

            for (int j = 0; j < futureTrans.length; j++) {
              final t = futureTrans[j];
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

              // Calculate new date based on offset (j + 1)
              final newDate = calculateRecurrentDate(dataCompetencia, finalPeriod, finalFreq, j + 1);

              final int nextParcel = currentParcel + j + 1;
              final String newDesc = totalParcelas == null
                  ? baseDesc
                  : '$baseDesc (Parcela $nextParcel/$totalParcelas)';

              // Stage transaction update
              ops.add({
                'action': 'update',
                'databaseId': Core.databaseId,
                'tableId': Core.tableTransacoes,
                'rowId': t.id,
                'data': {
                  'descricao': newDesc,
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

              // Stage division deletes and creates
              for (final oldDiv in t.divisoes) {
                ops.add({
                  'action': 'delete',
                  'databaseId': Core.databaseId,
                  'tableId': Core.tableDivisaoTransacoes,
                  'rowId': oldDiv.id,
                });
              }
              for (final divItem in divisao) {
                final String rContato = divItem['contatoResponsavel'] as String;
                final double rPeso = (divItem['peso'] as num).toDouble();
                ops.add({
                  'action': 'create',
                  'databaseId': Core.databaseId,
                  'tableId': Core.tableDivisaoTransacoes,
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
            // Update the recurrence row itself
            await tablesDB.updateRow(
              databaseId: Core.databaseId,
              tableId: Core.tableTransacaoRecorrencias,
              rowId: original.recorrencia!.id,
              data: {
                if (tipoRecorrencia != null) 'tipoRecorrencia': tipoRecorrencia,
                if (frequencia != null) 'frequencia': frequencia,
                'totalParcelas': totalParcelas,
                if (parcelaInicio != null) 'parcelaInicio': parcelaInicio,
              },
            );

            // Sort all transactions chronologically
            final allSeriesTrans = List<TransacaoModel>.from(allRecTrans);
            allSeriesTrans.sort((a, b) => a.dataCompetencia.compareTo(b.dataCompetencia));

            final int idxEdit = allSeriesTrans.indexWhere((t) => t.id == original.id);

            final String finalPeriod = tipoRecorrencia ?? original.recorrencia!.tipoRecorrencia;
            final int finalFreq = frequencia ?? original.recorrencia!.frequencia ?? 1;

            // Rebuild base description
            String baseDesc = descricao;
            final match = RegExp(r'^(.*)\s\(Parcela\s\d+/\d+\)$').firstMatch(descricao);
            if (match != null) {
              baseDesc = match.group(1)!;
            }
            newMainDesc = totalParcelas == null
                ? baseDesc
                : '$baseDesc (Parcela ${(idxEdit != -1 ? idxEdit + 1 : 1)}/$totalParcelas)';

            for (int j = 0; j < allSeriesTrans.length; j++) {
              final t = allSeriesTrans[j];
              if (t.id == original.id) continue;

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

              // Calculate new date based on offset from edited transaction
              final int offset = j - idxEdit;
              final newDate = calculateRecurrentDate(dataCompetencia, finalPeriod, finalFreq, offset);

              final int nextParcel = j + 1;
              final String newDesc = totalParcelas == null
                  ? baseDesc
                  : '$baseDesc (Parcela $nextParcel/$totalParcelas)';

              // Stage transaction update
              ops.add({
                'action': 'update',
                'databaseId': Core.databaseId,
                'tableId': Core.tableTransacoes,
                'rowId': t.id,
                'data': {
                  'descricao': newDesc,
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

              // Stage division deletes and creates
              for (final oldDiv in t.divisoes) {
                ops.add({
                  'action': 'delete',
                  'databaseId': Core.databaseId,
                  'tableId': Core.tableDivisaoTransacoes,
                  'rowId': oldDiv.id,
                });
              }
              for (final divItem in divisao) {
                final String rContato = divItem['contatoResponsavel'] as String;
                final double rPeso = (divItem['peso'] as num).toDouble();
                ops.add({
                  'action': 'create',
                  'databaseId': Core.databaseId,
                  'tableId': Core.tableDivisaoTransacoes,
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
      }

      // 2. Stage current transaction update
      ops.add({
        'action': 'update',
        'databaseId': Core.databaseId,
        'tableId': Core.tableTransacoes, // transacoes
        'rowId': id,
        'data': {
          'descricao': newMainDesc,
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
          'databaseId': Core.databaseId,
          'tableId': Core.tableDivisaoTransacoes,
          'rowId': oldDiv.id,
        });
      }

      for (final divItem in divisao) {
        final String rContato = divItem['contatoResponsavel'] as String;
        final double rPeso = (divItem['peso'] as num).toDouble();
        ops.add({
          'action': 'create',
          'databaseId': Core.databaseId,
          'tableId': Core.tableDivisaoTransacoes,
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
          final allRecTrans = await _fetchRecurrenceSeries(
            tablesDB,
            original.recorrencia!.id,
          );

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
          'databaseId': Core.databaseId,
          'tableId': Core.tableTransacoes,
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
        final allRecTrans = await _fetchRecurrenceSeries(tablesDB, recId);

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
            'databaseId': Core.databaseId,
            'tableId': Core.tableDivisaoTransacoes,
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
          'databaseId': Core.databaseId,
          'tableId': Core.tableTransacoes, // transacoes
          'rowId': t.id,
        });
      }

      if (transacao.recorrencia != null && deleteOption == 'all') {
        ops.add({
          'action': 'delete',
          'databaseId': Core.databaseId,
          'tableId': Core.tableTransacaoRecorrencias,
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
        databaseId: Core.databaseId,
        tableId: Core.tableContatos,
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
        databaseId: Core.databaseId,
        tableId: Core.tableContatos,
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

  Future<List<TransacaoModel>> _fetchRecurrenceSeries(
    TablesDB tablesDB,
    String recurrenceId,
  ) async {
    final recTransDocs = await tablesDB.listRows(
      databaseId: Core.databaseId,
      tableId: Core.tableTransacoes,
      queries: [
        Query.equal('recorrencia', [recurrenceId]),
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

    final List<TransacaoModel> allRecTrans = [];
    for (final doc in recTransDocs.rows) {
      final map = Map<String, dynamic>.from(doc.data);
      map['\$id'] = doc.$id;
      allRecTrans.add(TransacaoModel.fromMap(map));
    }

    final List<String> recTransIds = allRecTrans.map((t) => t.id).toList();
    if (recTransIds.isNotEmpty) {
      final List<DivisaoTransacaoModel> allRecDivs = [];
      for (int k = 0; k < recTransIds.length; k += 100) {
        final chunkIds = recTransIds.sublist(
          k,
          k + 100 > recTransIds.length ? recTransIds.length : k + 100,
        );
        final divsDocs = await tablesDB.listRows(
          databaseId: Core.databaseId,
          tableId: Core.tableDivisaoTransacoes,
          queries: [
            Query.equal('transacao', chunkIds),
            Query.limit(5000),
          ],
        );
        allRecDivs.addAll(
          divsDocs.rows.map((d) => DivisaoTransacaoModel.fromMap(d.data)),
        );
      }

      for (int i = 0; i < allRecTrans.length; i++) {
        final t = allRecTrans[i];
        final divsForT = allRecDivs.where((d) => d.transacaoId == t.id).toList();
        allRecTrans[i] = t.copyWith(divisoes: divsForT);
      }
    }

    return allRecTrans;
  }

  Future<bool> deleteContato(String id) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);
      await tablesDB.deleteRow(
        databaseId: Core.databaseId,
        tableId: Core.tableContatos,
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
