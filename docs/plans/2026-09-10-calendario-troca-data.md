# Alteração de Data de Execução no Calendário - Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Permitir que o usuário altere a data e horário de execução de um hábito ou tarefa diretamente pela tela de calendário (`CalendarioPage`) através de arrastar e soltar (drag & drop) e de um modal de detalhes com seletores de data e horário (date & time picker), com persistência otimista no Drift SQLite e sincronização no Appwrite.

**Architecture:** A nova data de execução é persistida na coluna `dataCriacao` no Appwrite (`tableHistoricoTarefasHabitos`) e na coluna `createdAt` no Drift SQLite local. A alteração é aplicada imediatamente no SQLite local (`optimistic update`), reemitida pelo stream reativo `watchHistorico`, salva na fila offline `pending_tarefas_habitos_syncs` e enviada à API remota do Appwrite via `updateRow`. A tela de calendário (`SfCalendar`) habilita `allowDragAndDrop` e substitui o diálogo direto de exclusão por um modal com tokens do Design System que permite reagendar ou excluir.

**Tech Stack:** Flutter, MobX, Drift (SQLite), Appwrite TablesDB, Syncfusion Flutter Calendar (`SfCalendar`), Design System Pastel (`AppColors`, `AppRadius`, `AppSpacing`, `AppTypography`).

---

### Task 1: Adicionar coluna `dataCriacao` no Appwrite e suporte a parsing no modelo/extensões

**Files:**
- Modify: `lib/app/capacitacao/tarefas_habitos/historico_controller.dart:67-73`
- Modify: `lib/app/capacitacao/tarefas_habitos/calendario_controller.dart:67-73`
- Modify: `lib/models/historico_item_model.dart:42-52`
- Test: `test/unit/historico_item_model_test.dart`

**Step 1: Criar coluna `dataCriacao` na tabela `tableHistoricoTarefasHabitos` no Appwrite**
Criar a coluna datetime `dataCriacao` via MCP `tables_db_create_datetime_column` na tabela `6741f10d000d985e4af9` do database `671f6e1600022832cba5`.

**Step 2: Escrever o teste que valida parsing de dataCriacao e fallback para createdAt**
```dart
test('HistoricoItemModel parses dataCriacao when available and falls back to createdAt', () {
  // Verificação de conversão com dataCriacao ISO string ou int e fallback
});
```

**Step 3: Executar teste para verificar falha/comportamento**
Run: `fvm flutter test test/unit/historico_item_model_test.dart`

**Step 4: Implementar suporte em `HistoricoTransformDocumentList` e `CalendarioTransformRowList`**
Se `e1.data['dataCriacao']` estiver presente, fazer parse; caso contrário, usar `e1.$createdAt`.

**Step 5: Executar testes e verificar aprovação**
Run: `fvm flutter test test/unit/historico_item_model_test.dart`
Expected: PASS

**Step 6: Commit**
```bash
git add lib/models/historico_item_model.dart lib/app/capacitacao/tarefas_habitos/historico_controller.dart lib/app/capacitacao/tarefas_habitos/calendario_controller.dart test/unit/historico_item_model_test.dart
git commit -m "feat(historico): add dataCriacao parsing support with createdAt fallback"
```

---

### Task 2: Implementar método `updateHistoricoItemDate` na interface e repositórios

**Files:**
- Modify: `lib/repositories/tarefa_habito_repository.dart:65-70`
- Modify: `lib/repositories/appwrite_tarefa_habito_repository.dart:318-327`
- Modify: `lib/repositories/drift_tarefa_habito_repository.dart:405-430`
- Test: `test/drift_tarefa_habito_repository_test.dart`

**Step 1: Adicionar teste unitário de `updateHistoricoItemDate` no DriftTarefaHabitoRepository**
```dart
test('updateHistoricoItemDate updates createdAt locally, queues offline sync and calls remote', () async {
  // Teste de atualização otimista no SQLite, alteração em tempo real e enfileiramento offline
});
```

**Step 2: Executar teste para verificar falha (método inexistente)**
Run: `fvm flutter test test/drift_tarefa_habito_repository_test.dart`
Expected: Erro de compilação ou falha

**Step 3: Adicionar método na interface `TarefaHabitoRepository`**
```dart
Future<bool> updateHistoricoItemDate({
  required String id,
  required DateTime newDate,
});
```

**Step 4: Implementar no `AppwriteTarefaHabitoRepository`**
```dart
@override
Future<bool> updateHistoricoItemDate({
  required String id,
  required DateTime newDate,
}) async {
  final TablesDB tablesDB = TablesDB(databases.client);
  await tablesDB.updateRow(
    databaseId: Core.databaseId,
    tableId: Core.tableHistoricoTarefasHabitos,
    rowId: id,
    data: {'dataCriacao': newDate.toUtc().toIso8601String()},
  );
  return true;
}
```

**Step 5: Implementar no `DriftTarefaHabitoRepository`**
- Atualizar `HistoricoTarefasHabitosCompanion(createdAt: Value(newDate))` na tabela do Drift SQLite.
- Adicionar ação `'updateHistoricoDate'` na fila `_addPendingSync`.
- Adicionar processamento de `'updateHistoricoDate'` em `flushPendingSyncs`.
- Chamar `remoteRepository.updateHistoricoItemDate`.

**Step 6: Executar testes para verificar aprovação**
Run: `fvm flutter test test/drift_tarefa_habito_repository_test.dart`
Expected: PASS

**Step 7: Commit**
```bash
git add lib/repositories/tarefa_habito_repository.dart lib/repositories/appwrite_tarefa_habito_repository.dart lib/repositories/drift_tarefa_habito_repository.dart test/drift_tarefa_habito_repository_test.dart
git commit -m "feat(repository): implement updateHistoricoItemDate with offline sync support"
```

---

### Task 3: Implementar método `updateHistoricoDate` em `HistoricoController`

**Files:**
- Modify: `lib/app/capacitacao/tarefas_habitos/historico_controller.dart:180-200`
- Test: `test/unit/historico_controller_test.dart`

**Step 1: Escrever teste unitário para `updateHistoricoDate` no `HistoricoController`**
```dart
test('updateHistoricoDate calls repository and triggers task reload', () async {
  // Teste de chamada ao repositório e retorno de sucesso
});
```

**Step 2: Executar teste para verificar falha**
Run: `fvm flutter test test/unit/historico_controller_test.dart`
Expected: FAIL

**Step 3: Implementar `updateHistoricoDate` no `HistoricoController`**
```dart
Future<bool> updateHistoricoDate(String id, DateTime newDate) async {
  try {
    final success = await Core.tarefaHabitoRepository.updateHistoricoItemDate(
      id: id,
      newDate: newDate,
    );
    if (success) {
      await Core.tarefasHabitosController.loadDocuments();
    }
    return success;
  } catch (e) {
    log('Error updating history date: $e');
    return false;
  }
}
```

**Step 4: Executar teste para verificar aprovação**
Run: `fvm flutter test test/unit/historico_controller_test.dart`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/app/capacitacao/tarefas_habitos/historico_controller.dart test/unit/historico_controller_test.dart
git commit -m "feat(controller): add updateHistoricoDate method in HistoricoController"
```

---

### Task 4: Habilitar Drag & Drop e Modal de Edição de Data/Hora na `CalendarioPage`

**Files:**
- Modify: `lib/app/capacitacao/tarefas_habitos/calendario_page.dart`
- Test: `test/app/capacitacao/tarefas_habitos/calendario_page_test.dart`

**Step 1: Escrever teste de widget para `CalendarioPage`**
- Verificar que o calendário renderiza com `allowDragAndDrop = true`.
- Ao tocar em um compromisso, o modal de detalhes abre com informações do item, botão "Alterar Data e Horário" e botão "Remover".

**Step 2: Executar teste para verificar falha**
Run: `fvm flutter test test/app/capacitacao/tarefas_habitos/calendario_page_test.dart`
Expected: FAIL

**Step 3: Implementar drag & drop e modal de edição na `CalendarioPage`**
- Adicionar `allowDragAndDrop: true` e `onDragEnd: _handleAppointmentDragEnd`.
- No `_handleAppointmentDragEnd`: se `details.dropTime != null`, invoca `Core.historicoController.updateHistoricoDate` e exibe SnackBar.
- Criar `_showHistoricoDetailsModal(BuildContext context, HistoricoItemModel item)` usando tokens do Design System (`AppColors`, `AppRadius.roundedXl`, `AppSpacing`, `AppTypography`).
- Adicionar fluxo com `showDatePicker` e `showTimePicker` temáticos para alteração manual da data e hora da execução.

**Step 4: Executar testes de widget e verificar aprovação**
Run: `fvm flutter test test/app/capacitacao/tarefas_habitos/calendario_page_test.dart`
Expected: PASS

**Step 5: Commit**
```bash
git add lib/app/capacitacao/tarefas_habitos/calendario_page.dart test/app/capacitacao/tarefas_habitos/calendario_page_test.dart
git commit -m "feat(calendar): enable drag and drop and details modal with date time picker"
```

---

### Task 5: Verificação Global e Documentação

**Files:**
- Modify: `README.md` (se relevante documentar suporte a reagendamento no calendário)
- Run: `fvm flutter analyze`
- Run: `fvm flutter test`

**Step 1: Executar análise estática do Flutter**
Run: `fvm flutter analyze`
Expected: Zero errors / warnings

**Step 2: Executar suite de testes completa**
Run: `fvm flutter test`
Expected: Todos os testes passando

**Step 3: Commit final**
```bash
git add README.md
git commit -m "docs: update README with calendar execution rescheduling capability"
```
