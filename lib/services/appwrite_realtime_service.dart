import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/repositories/drift_financas_repository.dart';
import 'package:ppvdigital/repositories/drift_tarefa_habito_repository.dart';

class AppwriteRealtimeService {
  AppwriteRealtimeService(this.client);

  final Client client;
  RealtimeSubscription? _subscription;
  String? _activeUserId;

  void startSubscription({required String userId}) {
    if (_activeUserId == userId && _subscription != null) {
      return;
    }
    stopSubscription();
    _activeUserId = userId;

    try {
      final realtime = Realtime(client);
      final String db = Core.databaseId;

      final List<String> channels = [
        'databases.$db.collections.${Core.tableTransacoes}.documents',
        'databases.$db.collections.${Core.tableContas}.documents',
        'databases.$db.collections.${Core.tableCategoriasTransacoes}.documents',
        'databases.$db.collections.${Core.tableContatos}.documents',
        'databases.$db.collections.${Core.tableDivisaoTransacoes}.documents',
      ];

      log('Starting Appwrite Realtime subscription for user: $userId');
      _subscription = realtime.subscribe(channels);

      _subscription!.stream.listen(
        (RealtimeMessage message) {
          _handleMessage(message);
        },
        onError: (error) {
          log('Appwrite Realtime stream error: $error');
        },
      );
    } catch (e) {
      log('Failed to initialize Appwrite Realtime: $e');
    }
  }

  void _handleMessage(RealtimeMessage message) {
    try {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(message.payload);

      for (final String event in message.events) {
        final String action = _extractAction(event);
        final String tableId = _extractTableId(event);

        if (action.isNotEmpty && tableId.isNotEmpty) {
          log('Realtime event received: $action on table $tableId');
          final financasRepo = Core.financasRepository;
          if (financasRepo is DriftFinancasRepository) {
            financasRepo.handleRealtimeEvent(
              tableId: tableId,
              action: action,
              payload: payload,
            );
          }
          final tarefaRepo = Core.tarefaHabitoRepository;
          if (tarefaRepo is DriftTarefaHabitoRepository) {
            tarefaRepo.handleRealtimeEvent(
              tableId: tableId,
              action: action,
              payload: payload,
            );
          }
          break;
        }
      }
    } catch (e) {
      log('Error handling Realtime message: $e');
    }
  }

  String _extractAction(String event) {
    if (event.endsWith('.create')) return 'create';
    if (event.endsWith('.update')) return 'update';
    if (event.endsWith('.delete')) return 'delete';
    return '';
  }

  String _extractTableId(String event) {
    final parts = event.split('.');
    final collectionsIdx = parts.indexOf('collections');
    if (collectionsIdx != -1 && collectionsIdx + 1 < parts.length) {
      return parts[collectionsIdx + 1];
    }
    return '';
  }

  void stopSubscription() {
    try {
      _subscription?.close();
    } catch (e) {
      log('Error closing Realtime subscription: $e');
    }
    _subscription = null;
    _activeUserId = null;
  }
}
