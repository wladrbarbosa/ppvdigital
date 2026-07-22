import 'dart:async';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:mobx/mobx.dart' as mobx;
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/divisao_transacao_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/repositories/financas_repository.dart';

class FinancasController {
  FinancasController(this.repository);
  final FinancasRepository repository;

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

  StreamSubscription? _contatosSub;
  StreamSubscription? _contasSub;
  StreamSubscription? _categoriasSub;
  StreamSubscription? _transacoesSub;
  DateTime? _subscribedMonth;

  Future<bool> loadDocuments({DateTime? selectedMonth}) async {
    final DateTime targetMonth = selectedMonth ?? _lastSelectedMonth;
    final bool isAlreadySubscribed = _contatosSub != null &&
        _subscribedMonth != null &&
        _subscribedMonth!.year == targetMonth.year &&
        _subscribedMonth!.month == targetMonth.month;

    _lastSelectedMonth = targetMonth;

    return await mobx.runInAction(() async {
      try {
        if (Core.loginController.currentUser == null) {
          await Core.loginController.loadUser();
        }
        final String user = Core.loginController.currentUser?.$id ?? '';

        // Only resubscribe to streams if month changed or streams aren't active yet
        if (!isAlreadySubscribed) {
          _subscribedMonth = targetMonth;
          await _subscribeToStreams(user, targetMonth);
        }

        // Start remote sync in background (non-blocking)
        _syncRemoteDataInBackground(user, targetMonth);

        return true;
      } catch (e) {
        log('Error loading finances: $e');
        return false;
      }
    }, name: 'loadDocuments');
  }

  Future<void> _subscribeToStreams(String user, DateTime targetMonth) async {
    _contatosSub?.cancel();
    final contatosStream = repository.watchContatos(usuarioId: user);
    try {
      final firstData = await contatosStream.first;
      mobx.runInAction(() {
        _contatosList.clear();
        _contatosList.addAll(firstData);
      });
    } catch (_) {}
    _contatosSub = contatosStream.listen((data) {
      mobx.runInAction(() {
        _contatosList.clear();
        _contatosList.addAll(data);
      });
    });

    _contasSub?.cancel();
    final contasStream = repository.watchContas(usuarioId: user);
    try {
      final firstData = await contasStream.first;
      mobx.runInAction(() {
        _contasList.clear();
        _contasList.addAll(firstData);
      });
    } catch (_) {}
    _contasSub = contasStream.listen((data) {
      mobx.runInAction(() {
        _contasList.clear();
        _contasList.addAll(data);
      });
    });

    _categoriasSub?.cancel();
    final categoriasStream = repository.watchCategorias(usuarioId: user);
    try {
      final firstData = await categoriasStream.first;
      mobx.runInAction(() {
        _categoriasList.clear();
        _categoriasList.addAll(firstData);
      });
    } catch (_) {}
    _categoriasSub = categoriasStream.listen((data) {
      mobx.runInAction(() {
        _categoriasList.clear();
        _categoriasList.addAll(data);
      });
    });

    _transacoesSub?.cancel();
    final transacoesStream = repository.watchTransacoes(
      usuarioId: user,
      contaIds: [],
    );
    try {
      final firstData = await transacoesStream.first;
      mobx.runInAction(() {
        final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
        final loadedTrans = firstData
            .where(
              (t) => t.dataCompetencia.isAfter(
                firstDayOfMonth.subtract(const Duration(seconds: 1)),
              ),
            )
            .toList();
        final loadedPastTrans = firstData
            .where((t) => t.dataCompetencia.isBefore(firstDayOfMonth))
            .toList();

        _transacoesList.clear();
        _transacoesList.addAll(loadedTrans);
        _transacoesList.addAll(loadedPastTrans);
      });
    } catch (_) {}
    _transacoesSub = transacoesStream.listen((data) {
      mobx.runInAction(() {
        final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
        final loadedTrans = data
            .where(
              (t) => t.dataCompetencia.isAfter(
                firstDayOfMonth.subtract(const Duration(seconds: 1)),
              ),
            )
            .toList();
        final loadedPastTrans = data
            .where((t) => t.dataCompetencia.isBefore(firstDayOfMonth))
            .toList();

        _transacoesList.clear();
        _transacoesList.addAll(loadedTrans);
        _transacoesList.addAll(loadedPastTrans);
      });
    });
  }

  final mobx.Observable<bool> _isSyncing = mobx.Observable<bool>(
    false,
    name: 'isSyncing',
  );
  bool get isSyncing => _isSyncing.value;

  DateTime? _lastSyncTime;
  DateTime? _lastSyncMonth;
  final Set<String> _syncedMonths = {};

  Future<void> _syncRemoteDataInBackground(
    String user,
    DateTime targetMonth,
  ) async {
    final now = DateTime.now();
    final String monthKey = '${targetMonth.year}_${targetMonth.month}';
    final bool monthChanged = _lastSyncMonth == null ||
        _lastSyncMonth!.year != targetMonth.year ||
        _lastSyncMonth!.month != targetMonth.month;

    // Skip throttling if month changed or month has never been synced in this session
    final bool shouldSkipThrottle =
        monthChanged || !_syncedMonths.contains(monthKey);

    if (!shouldSkipThrottle &&
        _lastSyncTime != null &&
        now.difference(_lastSyncTime!) < const Duration(minutes: 3)) {
      return;
    }

    _lastSyncMonth = targetMonth;

    mobx.runInAction(() {
      _isSyncing.value = true;
    });
    try {
      final String? lastSyncStr =
          await Core.database.getSetting('last_financas_sync_time');
      final DateTime? lastSyncedAt =
          lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      // 0. Fetch and cache contatos incrementally
      final contatos = await repository.getContatos(
        usuarioId: user,
        lastSyncedAt: lastSyncedAt,
      );

      // Auto-create a contact for the current user if they don't have one
      final bool hasUserContato = contatos.any((c) => c.userId == user);
      if (!hasUserContato && user.isNotEmpty) {
        final String currentUserName =
            Core.loginController.currentUser?.name ?? 'Eu';
        final String currentUserEmail =
            Core.loginController.currentUser?.email ?? '';
        try {
          await repository.createContato(
            ownerId: user,
            nome: currentUserName.isNotEmpty ? '$currentUserName (Eu)' : 'Eu',
            email: currentUserEmail.isNotEmpty ? currentUserEmail : null,
            userId: user,
          );
        } catch (e) {
          log('Error auto-creating user contact: $e');
        }
      }

      // 1. Fetch and cache contas incrementally
      final contas = await repository.getContas(
        usuarioId: user,
        lastSyncedAt: lastSyncedAt,
      );
      final List<String> contaIds = contas.map((c) => c.id).toList();

      // 2. Fetch and cache categorias incrementally
      await repository.getCategorias(
        usuarioId: user,
        lastSyncedAt: lastSyncedAt,
      );

      if (contaIds.isNotEmpty) {
        final String? monthSyncedSetting =
            await Core.database.getSetting('synced_month_$monthKey');
        final bool isMonthAlreadySynced =
            monthSyncedSetting != null || _syncedMonths.contains(monthKey);

        // 3. Fetch and cache transactions for targetMonth:
        // Pass lastSyncedAt ONLY if this targetMonth was already full-synced once.
        await repository.getTransacoes(
          usuarioId: user,
          contaIds: contaIds,
          targetMonth: targetMonth,
          lastSyncedAt: isMonthAlreadySynced ? lastSyncedAt : null,
        );

        _syncedMonths.add(monthKey);
        await Core.database.setSetting(
          'synced_month_$monthKey',
          now.toIso8601String(),
        );

        // 4. Fetch and cache past transactions (before targetMonth) for accumulated balance:
        final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month);
        final String? pastSyncedSetting =
            await Core.database.getSetting('synced_past_financas');
        final bool isPastAlreadySynced = pastSyncedSetting != null;

        await repository.getTransacoes(
          usuarioId: user,
          contaIds: contaIds,
          beforeDate: firstDayOfMonth,
          lastSyncedAt: isPastAlreadySynced ? lastSyncedAt : null,
        );
        await Core.database.setSetting(
          'synced_past_financas',
          now.toIso8601String(),
        );
      }

      _lastSyncTime = now;
      await Core.database.setSetting(
        'last_financas_sync_time',
        now.toIso8601String(),
      );
    } catch (e) {
      log('Background sync failed: $e');
    } finally {
      mobx.runInAction(() {
        _isSyncing.value = false;
      });
    }
  }

  void reset() {
    _contatosSub?.cancel();
    _contasSub?.cancel();
    _categoriasSub?.cancel();
    _transacoesSub?.cancel();

    mobx.runInAction(() {
      _contasList.clear();
      _categoriasList.clear();
      _contatosList.clear();
      _transacoesList.clear();
      _divisoesList.clear();
      _isSyncing.value = false;
    });
  }

  Future<void> updateAccountBalance(String contaId, double amountDiff) async {
    final int idx = _contasList.indexWhere((c) => c.id == contaId);
    if (idx != -1) {
      final account = _contasList[idx];
      final double newSaldo = account.saldoAtual + amountDiff;
      mobx.runInAction(() {
        _contasList[idx] = account.copyWith(saldoAtual: newSaldo);
      });
      await repository.updateAccountBalance(
        contaId: contaId,
        newSaldo: newSaldo,
      );
    }
  }

  Future<bool> createConta(String name, double saldoInicial) async {
    try {
      if (Core.loginController.currentUser == null) {
        await Core.loginController.loadUser();
      }
      final String user = Core.loginController.currentUser?.$id ?? '';

      await repository.createConta(
        name: name,
        saldoInicial: saldoInicial,
        usuarioId: user,
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
      await repository.updateConta(id: id, name: name, saldoAtual: saldoAtual);
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error updating account: $e');
      return false;
    }
  }

  Future<bool> deleteConta(String id) async {
    try {
      await repository.deleteConta(id: id);
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

      await repository.createCategoria(
        name: name,
        icone: icone,
        hexColor: hexColor,
        usuarioId: user,
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
      await repository.updateCategoria(
        id: id,
        name: name,
        icone: icone,
        hexColor: hexColor,
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
      await repository.deleteCategoria(id: id);
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
    required bool recorrenciaIndeterminada,
    required String tipoRecorrencia,
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

      String? recId;

      if (recorrente) {
        recId = await repository.createRecorrenciaRow(
          tipoRecorrencia: tipoRecorrencia,
          frequencia: frequencia,
          totalParcelas: recorrenciaIndeterminada ? null : totalParcelas,
          parcelaInicio: recorrenciaIndeterminada ? null : parcelaInicio,
          fimRecorrencia: fimRecorrencia,
        );
      }

      final int remainingParcels = totalParcelas - parcelaInicio + 1;
      final int loopLimit = recorrente
          ? (recorrenciaIndeterminada ? 24 : remainingParcels)
          : 1;

      final List<Map<String, dynamic>> ops = [];

      if (recorrente) {
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
      } else {
        // Single non-recurrent transaction (normal flow)
        final bool isDivision =
            divisao.length > 1 &&
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
            ops.add({
              'action': 'create',
              'databaseId': Core.databaseId,
              'tableId': Core.tableTransacoes,
              'rowId': tRowId,
              'data': {
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
            });

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

            // 2. Create refund transactions from other contacts
            for (final divItem in divisao) {
              final String rContato = divItem['contatoResponsavel'] as String;
              if (rContato == userContatoId) continue;
              final double rPeso = (divItem['peso'] as num).toDouble();
              final double shareValue = valor * (rPeso / totalWeights);

              final String refundType = tipo == 'despesa'
                  ? 'receita'
                  : 'despesa';
              final String? refDevedor = refundType == 'receita'
                  ? rContato
                  : null;
              final String? refCredor = refundType == 'despesa'
                  ? rContato
                  : null;

              ops.add({
                'action': 'create',
                'databaseId': Core.databaseId,
                'tableId': Core.tableTransacoes,
                'rowId': ID.unique(),
                'data': {
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
              });

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

            final String? refDevedor = tipo == 'receita'
                ? pagadorRecebedorId
                : null;
            final String? refCredor = tipo == 'despesa'
                ? pagadorRecebedorId
                : null;

            ops.add({
              'action': 'create',
              'databaseId': Core.databaseId,
              'tableId': Core.tableTransacoes,
              'rowId': ID.unique(),
              'data': {
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
            });

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
          ops.add({
            'action': 'create',
            'databaseId': Core.databaseId,
            'tableId': Core.tableTransacoes,
            'rowId': tRowId,
            'data': {
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
          });

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
      }

      if (ops.isNotEmpty) {
        await repository.executeBatchOperations(ops);
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

      String? updatedRecId = original.recorrencia?.id;

      // Local helper function to calculate recurrent dates
      DateTime calculateRecurrentDate(
        DateTime baseDate,
        String period,
        int freq,
        int offset,
      ) {
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
          // Check if ONLY consolidada status was changed
          String cleanDesc(String d) {
            final m = RegExp(r'^(.*)\s\(Parcela\s\d+/\d+\)$').firstMatch(d);
            return m != null ? m.group(1)! : d;
          }

          final bool isOnlyConsolidationChanged =
              cleanDesc(descricao) == cleanDesc(original.descricao) &&
              (valor - original.valor).abs() < 0.001 &&
              tipo == original.tipo &&
              dataCompetencia.isAtSameMomentAs(original.dataCompetencia) &&
              contaId == original.conta?.id &&
              contaDestinoId == original.contaDestino?.id &&
              categoriaId == original.categoria?.id &&
              devedorContatoId == original.devedorContato?.id &&
              credorContatoId == original.credorContato?.id;

          if (isOnlyConsolidationChanged) {
            updatedRecId = original.recorrencia?.id;
          } else {
            updatedRecId = null;
            // Strip any suffix for single edited transaction split off from recurrence
            final match = RegExp(
              r'^(.*)\s\(Parcela\s\d+/\d+\)$',
            ).firstMatch(descricao);
            if (match != null) {
              newMainDesc = match.group(1)!;
            }
          }
        } else {
          final allRecTrans = await repository.getRecurrenceSeries(
            recurrenceId: original.recorrencia!.id,
          );

          if (optionRecorrencia == 'current_and_future') {
            // create new recurrence row
            final originalRec = original.recorrencia!;
            final newRecId = await repository.createRecorrenciaRow(
              tipoRecorrencia: tipoRecorrencia ?? originalRec.tipoRecorrencia,
              frequencia: frequencia ?? originalRec.frequencia ?? 0,
              totalParcelas: totalParcelas,
              parcelaInicio: parcelaInicio ?? originalRec.parcelaInicio,
              fimRecorrencia: originalRec.fimRecorrencia,
            );
            updatedRecId = newRecId;

            // Sort future transactions chronologically
            final futureTrans = allRecTrans
                .where(
                  (t) =>
                      t.id != original.id &&
                      t.dataCompetencia.isAfter(original.dataCompetencia),
                )
                .toList();
            futureTrans.sort(
              (a, b) => a.dataCompetencia.compareTo(b.dataCompetencia),
            );

            final String finalPeriod =
                tipoRecorrencia ?? originalRec.tipoRecorrencia;
            final int finalFreq = frequencia ?? originalRec.frequencia ?? 1;

            // Rebuild description for the current edited transaction
            String baseDesc = descricao;
            final match = RegExp(
              r'^(.*)\s\(Parcela\s\d+/\d+\)$',
            ).firstMatch(descricao);
            if (match != null) {
              baseDesc = match.group(1)!;
            }
            final int currentParcel =
                parcelaInicio ?? originalRec.parcelaInicio ?? 1;
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
              final newDate = calculateRecurrentDate(
                dataCompetencia,
                finalPeriod,
                finalFreq,
                j + 1,
              );

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
            await repository.updateRow(
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
            allSeriesTrans.sort(
              (a, b) => a.dataCompetencia.compareTo(b.dataCompetencia),
            );

            final int idxEdit = allSeriesTrans.indexWhere(
              (t) => t.id == original.id,
            );

            final String finalPeriod =
                tipoRecorrencia ?? original.recorrencia!.tipoRecorrencia;
            final int finalFreq =
                frequencia ?? original.recorrencia!.frequencia ?? 1;

            // Rebuild base description
            String baseDesc = descricao;
            final match = RegExp(
              r'^(.*)\s\(Parcela\s\d+/\d+\)$',
            ).firstMatch(descricao);
            if (match != null) {
              baseDesc = match.group(1)!;
            }
            newMainDesc = totalParcelas == null
                ? baseDesc
                : '$baseDesc (Parcela ${idxEdit != -1 ? idxEdit + 1 : 1}/$totalParcelas)';

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
              final newDate = calculateRecurrentDate(
                dataCompetencia,
                finalPeriod,
                finalFreq,
                offset,
              );

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

      if (ops.isNotEmpty) {
        await repository.executeBatchOperations(ops);
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
      final List<Map<String, dynamic>> ops = [];
      final List<TransacaoModel> targetTransactions = [];

      for (final id in transIds) {
        final matches = transacoesList.where((t) => t.id == id);
        if (matches.isEmpty) continue;
        final original = matches.first;

        List<TransacaoModel> seriesToUpdate = [];
        if (original.recorrencia != null &&
            recurrenceOption != 'only_current') {
          final allRecTrans = await repository.getRecurrenceSeries(
            recurrenceId: original.recorrencia!.id,
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
        final Map<String, dynamic> updateData = {
          'descricao': t.descricao,
          'valor': t.valor,
          'tipo': t.tipo,
          'dataCompetencia': t.dataCompetencia.toIso8601String(),
          'consolidada': t.consolidada,
          'conta': t.conta?.id,
          'contaDestino': t.contaDestino?.id,
          'categoria': t.categoria?.id,
          'recorrencia': t.recorrencia?.id,
          'devedorContato': t.devedorContato?.id,
          'credorContato': t.credorContato?.id,
        };

        if (action == 'consolidar') {
          updateData['consolidada'] = newValue as bool;
        } else if (action == 'dataCompetencia') {
          final DateTime newDate = newValue as DateTime;
          if (transIds.contains(t.id)) {
            updateData['dataCompetencia'] = newDate.toIso8601String();
          } else {
            TransacaoModel? originalForT;
            for (final origId in transIds) {
              final matchesOrig = transacoesList.where((o) => o.id == origId);
              if (matchesOrig.isEmpty) continue;
              final orig = matchesOrig.first;
              if (t.recorrencia != null &&
                  orig.recorrencia != null &&
                  t.recorrencia!.id == orig.recorrencia!.id) {
                if (orig.dataCompetencia.isBefore(t.dataCompetencia)) {
                  if (originalForT == null ||
                      orig.dataCompetencia.isAfter(originalForT.dataCompetencia)) {
                    originalForT = orig;
                  }
                }
              }
            }

            if (originalForT != null) {
              final delta = newDate.difference(originalForT.dataCompetencia);
              updateData['dataCompetencia'] = t.dataCompetencia
                  .add(delta)
                  .toIso8601String();
            } else {
              updateData['dataCompetencia'] = newDate.toIso8601String();
            }
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

      if (ops.isNotEmpty) {
        await repository.executeBatchOperations(ops);
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
      List<TransacaoModel> toDelete = [];

      if (deleteOption == 'only_current' || transacao.recorrencia == null) {
        toDelete = [transacao];
      } else {
        final recId = transacao.recorrencia!.id;
        final allRecTrans = await repository.getRecurrenceSeries(
          recurrenceId: recId,
        );

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
        // Stage delete all division records
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

      if (ops.isNotEmpty) {
        await repository.executeBatchOperations(ops);
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

      await repository.createContato(
        ownerId: user,
        nome: nome,
        email: email,
        userId: userId,
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
      await repository.updateRow(
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

  Future<bool> deleteContato(String id) async {
    try {
      await repository.deleteRow(tableId: Core.tableContatos, rowId: id);
      await loadDocuments();
      return true;
    } catch (e) {
      log('Error deleting contact: $e');
      return false;
    }
  }
}
