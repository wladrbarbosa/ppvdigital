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

  void init() {
    databases = Databases(Core.client);
  }

  Future<bool> loadDocuments() async {
    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }
        final String user = Core.loginController.currentUser?.$id ?? '';
        final TablesDB tablesDB = TablesDB(databases.client);

        // 0. Load contatos
        final contatosDocs = await tablesDB.listRows(
          databaseId: '671f6e1600022832cba5',
          tableId: 'contatos',
          queries: [
            Query.equal('ownerId', [user]),
            Query.limit(5000),
          ],
        );
        _contatosList.clear();
        _contatosList.addAll(
          contatosDocs.rows.map((d) => ContatoModel.fromMap(d.data)),
        );

        final List<String> userContatoIds = _contatosList
            .map((c) => c.id)
            .toList();

        // 1. Load accounts
        final accountsDocs = await tablesDB.listRows(
          databaseId: '671f6e1600022832cba5',
          tableId: '671f7aa70014dda7507c', // contas
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
          databaseId: '671f6e1600022832cba5',
          tableId: 'categorias_transacoes',
          queries: [
            Query.equal('userId', [user]),
          ],
        );
        _categoriasList.clear();
        _categoriasList.addAll(
          catDocs.rows.map((d) => CategoriaTransacaoModel.fromMap(d.data)),
        );

        // 3. Load transactions
        final List<String> contaIds = contasList.map((c) => c.id).toList();
        final List<TransacaoModel> loadedTrans = [];

        if (contaIds.isNotEmpty) {
          // Query transactions where conta is one of the user's accounts
          final transDocs1 = await tablesDB.listRows(
            databaseId: '671f6e1600022832cba5',
            tableId: '671f7a6f000cb3ab17b9', // transacoes
            queries: [
              Query.equal('conta', contaIds),
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
            loadedTrans.add(TransacaoModel.fromMap(doc.data));
          }

          // Query transactions where contaDestino is one of the user's accounts (incoming transfers)
          final transDocs2 = await tablesDB.listRows(
            databaseId: '671f6e1600022832cba5',
            tableId: '671f7a6f000cb3ab17b9',
            queries: [
              Query.equal('contaDestino', contaIds),
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
              loadedTrans.add(TransacaoModel.fromMap(doc.data));
            }
          }
        }

        // Query divisions where user's contacts participate
        _divisoesList.clear();
        if (userContatoIds.isNotEmpty) {
          final divDocs = await tablesDB.listRows(
            databaseId: '671f6e1600022832cba5',
            tableId: 'divisao_transacoes',
            queries: [
              Query.equal('contatoResponsavel', userContatoIds),
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

        // Fetch divisions for loaded transactions to show in UI
        if (loadedTrans.isNotEmpty) {
          final List<String> loadedTransIds = loadedTrans
              .map((t) => t.id)
              .toList();
          final allDivsDocs = await tablesDB.listRows(
            databaseId: '671f6e1600022832cba5',
            tableId: 'divisao_transacoes',
            queries: [
              Query.equal('transacao', loadedTransIds),
              Query.limit(5000),
            ],
          );
          final List<DivisaoTransacaoModel> allDivs = allDivsDocs.rows
              .map((d) => DivisaoTransacaoModel.fromMap(d.data))
              .toList();

          for (int i = 0; i < loadedTrans.length; i++) {
            final t = loadedTrans[i];
            final divsForT = allDivs
                .where((d) => d.transacaoId == t.id)
                .toList();
            loadedTrans[i] = t.copyWith(divisoes: divsForT);
          }
        }

        _transacoesList.clear();
        _transacoesList.addAll(loadedTrans);

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
      databaseId: '671f6e1600022832cba5',
      tableId: '671f7aa70014dda7507c', // contas
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f7aa70014dda7507c', // contas
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f7aa70014dda7507c', // contas
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
        databaseId: '671f6e1600022832cba5',
        tableId: '671f7aa70014dda7507c', // contas
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'categorias_transacoes',
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'categorias_transacoes',
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'categorias_transacoes',
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
          databaseId: '671f6e1600022832cba5',
          tableId: 'transacao_recorrencia',
          rowId: ID.unique(),
          data: {
            'tipoRecorrencia': tipoRecorrencia,
            'frequencia': frequencia,
            'totalParcelas': recorrenciaIndeterminada ? null : totalParcelas,
            'parcelaInicio': recorrenciaIndeterminada ? null : 1,
            'fimRecorrencia': fimRecorrencia?.toIso8601String(),
          },
        );
        recId = recRow.$id;
      }

      final int loopLimit = recorrente
          ? (recorrenciaIndeterminada ? 24 : totalParcelas)
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
              ? '$descricao (Parcela $i/$totalParcelas)'
              : descricao;

          final String tRowId = ID.unique();

          // Stage transaction creation
          ops.add({
            'action': 'create',
            'databaseId': '671f6e1600022832cba5',
            'tableId': '671f7a6f000cb3ab17b9',
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
              'databaseId': '671f6e1600022832cba5',
              'tableId': 'divisao_transacoes',
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
          final chunk = ops.sublist(j, j + 100 > ops.length ? ops.length : j + 100);
          final String txId = (await tablesDB.createTransaction()).$id;
          await tablesDB.createOperations(
            transactionId: txId,
            operations: chunk,
          );
          await tablesDB.updateTransaction(
            transactionId: txId,
            commit: true,
          );
        }
      } else {
        // Single non-recurrent transaction (normal flow)
        final String tRowId = ID.unique();
        await tablesDB.createRow(
          databaseId: '671f6e1600022832cba5',
          tableId: '671f7a6f000cb3ab17b9',
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
            databaseId: '671f6e1600022832cba5',
            tableId: 'divisao_transacoes',
            rowId: ID.unique(),
            data: {
              'transacao': tRowId,
              'contatoResponsavel': rContato,
              'peso': rPeso,
            },
          );
        }
      }

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
  }) async {
    try {
      final TablesDB tablesDB = TablesDB(databases.client);

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
            databaseId: '671f6e1600022832cba5',
            tableId: 'transacao_recorrencia',
            rowId: ID.unique(),
            data: {
              'tipoRecorrencia': originalRec.tipoRecorrencia,
              'frequencia': originalRec.frequencia,
              'totalParcelas': originalRec.totalParcelas,
              'parcelaInicio': originalRec.parcelaInicio,
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

            // Update row
            await tablesDB.updateRow(
              databaseId: '671f6e1600022832cba5',
              tableId: '671f7a6f000cb3ab17b9',
              rowId: t.id,
              data: {
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
            );

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

            // Update divisions
            for (final oldDiv in t.divisoes) {
              await tablesDB.deleteRow(
                databaseId: '671f6e1600022832cba5',
                tableId: 'divisao_transacoes',
                rowId: oldDiv.id,
              );
            }
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              final double rPeso = (divItem['peso'] as num).toDouble();
              await tablesDB.createRow(
                databaseId: '671f6e1600022832cba5',
                tableId: 'divisao_transacoes',
                rowId: ID.unique(),
                data: {
                  'transacao': t.id,
                  'contatoResponsavel': rContato,
                  'peso': rPeso,
                },
              );
            }
          }
        } else if (optionRecorrencia == 'all') {
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

            // Update row
            await tablesDB.updateRow(
              databaseId: '671f6e1600022832cba5',
              tableId: '671f7a6f000cb3ab17b9',
              rowId: t.id,
              data: {
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
            );

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

            // Update divisions
            for (final oldDiv in t.divisoes) {
              await tablesDB.deleteRow(
                databaseId: '671f6e1600022832cba5',
                tableId: 'divisao_transacoes',
                rowId: oldDiv.id,
              );
            }
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              final double rPeso = (divItem['peso'] as num).toDouble();
              await tablesDB.createRow(
                databaseId: '671f6e1600022832cba5',
                tableId: 'divisao_transacoes',
                rowId: ID.unique(),
                data: {
                  'transacao': t.id,
                  'contatoResponsavel': rContato,
                  'peso': rPeso,
                },
              );
            }
          }
        }
      }

      // 2. Update current transaction
      await tablesDB.updateRow(
        databaseId: '671f6e1600022832cba5',
        tableId: '671f7a6f000cb3ab17b9', // transacoes
        rowId: id,
        data: {
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
      );

      // 3. Apply new balance effects if consolidated
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

      // 4. Update division rows (delete old and write new)
      for (final oldDiv in original.divisoes) {
        await tablesDB.deleteRow(
          databaseId: '671f6e1600022832cba5',
          tableId: 'divisao_transacoes',
          rowId: oldDiv.id,
        );
      }

      for (final divItem in divisao) {
        final String rContato = divItem['contatoResponsavel'] as String;
        final double rPeso = (divItem['peso'] as num).toDouble();
        await tablesDB.createRow(
          databaseId: '671f6e1600022832cba5',
          tableId: 'divisao_transacoes',
          rowId: ID.unique(),
          data: {
            'transacao': id,
            'contatoResponsavel': rContato,
            'peso': rPeso,
          },
        );
      }

      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating transaction: $e');
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

      for (final t in toDelete) {
        // Delete all division records
        for (final div in t.divisoes) {
          await tablesDB.deleteRow(
            databaseId: '671f6e1600022832cba5',
            tableId: 'divisao_transacoes',
            rowId: div.id,
          );
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

        // Delete the transaction itself
        await tablesDB.deleteRow(
          databaseId: '671f6e1600022832cba5',
          tableId: '671f7a6f000cb3ab17b9', // transacoes
          rowId: t.id,
        );
      }

      if (transacao.recorrencia != null && deleteOption == 'all') {
        await tablesDB.deleteRow(
          databaseId: '671f6e1600022832cba5',
          tableId: 'transacao_recorrencia',
          rowId: transacao.recorrencia!.id,
        );
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'contatos',
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'contatos',
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
        databaseId: '671f6e1600022832cba5',
        tableId: 'contatos',
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
