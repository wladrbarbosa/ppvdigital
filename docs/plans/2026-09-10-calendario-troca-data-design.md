# Design Document: Alteração de Data de Execução de Hábitos e Tarefas no Calendário

**Data:** 10 de Setembro de 2026  
**Status:** Aprovado  
**Autores:** Pair Programming (Antigravity & Usuário)

---

## 1. Visão Geral e Motivação

Atualmente, na visualização de calendário (`CalendarioPage`), os compromissos exibidos representam o histórico de execuções (`HistoricoItemModel`) de hábitos e tarefas. No entanto, o usuário não possuía uma forma de ajustar ou reagendar retroativamente ou prospectivamente uma execução diretamente pelo calendário. Ao tocar em um compromisso, apenas o diálogo de remoção era exibido, e o recurso de arrastar e soltar não estava habilitado.

Este documento detalha o design para permitir que o usuário altere a data/horário de uma execução de hábito ou tarefa por dois caminhos intuitivos:
1. **Arrastar e Soltar (Drag & Drop):** arrastar diretamente o compromisso para outro horário ou dia na grade do `SfCalendar`.
2. **Modal de Detalhes e Edição:** tocar no compromisso para visualizar os detalhes e acionar um seletor de data e horário (*Date & Time Picker*).

---

## 2. Metas e Não-Metas

### Metas
- Permitir edição de data/horário de uma execução (`HistoricoItemModel`) via drag & drop e via modal/picker.
- Atualização otimista imediata na base local Drift SQLite com emissão reativa no stream `watchHistorico`.
- Persistência no Appwrite através da coluna `dataCriacao` (datetime ISO 8601) na tabela `tableHistoricoTarefasHabitos`.
- Resiliência offline através da fila pendente `pending_tarefas_habitos_syncs`.
- Preservação da integridade do cálculo de frequência/metas dos hábitos (`_populatePeriodVezesPraticado`).
- Aderência estrita ao Design System do projeto (`AppColors`, `AppRadius`, `AppSpacing`, `AppTypography`).
- Testes automatizados unitários, de repositório e de interface.

### Não-Metas
- Alteração da data de agendamento de uma tarefa futura que ainda não foi executada (essa funcionalidade é gerenciada na edição da tarefa). O foco deste recurso é a data de *execução* (registro no histórico).

---

## 3. Arquitetura e Modelagem de Dados

### 3.1. Backend (Appwrite)
- Tabela de Histórico: `tableHistoricoTarefasHabitos` (`6741f10d000d985e4af9`).
- Nova Coluna: `dataCriacao` (tipo: `datetime`, opcional/nullable).
- Compatibilidade:
  - Se `dataCriacao` não for nulo, utiliza seu valor.
  - Se `dataCriacao` for nulo (registros criados antes desta alteração), utiliza o fallback para o sistema `$createdAt`.
- Ao atualizar a data, executa `tablesDB.updateRow` com `{ 'dataCriacao': newDate.toUtc().toIso8601String() }`. O Appwrite atualiza automaticamente `$updatedAt`, propagando para delta sync e Realtime.

### 3.2. Banco Local (Drift SQLite)
- Tabela `HistoricoTarefasHabitos`: já possui a coluna `createdAt` (`DateTimeColumn`). Não há necessidade de alteração de schema ou migração no SQLite.
- Atualização Otimista:
  ```dart
  await (database.update(database.historicoTarefasHabitos)
    ..where((h) => h.remoteId.equals(id)))
    .write(HistoricoTarefasHabitosCompanion(createdAt: Value(newDate)));
  ```

### 3.3. Fila de Sincronização Offline
- Adição da ação `updateHistoricoDate` em `_addPendingSync`:
  ```json
  {
    "actionType": "updateHistoricoDate",
    "id": "<historyId>",
    "newDate": "2026-09-10T15:30:00.000Z"
  }
  ```
- No método `flushPendingSyncs`, processa a ação invocando `remoteRepository.updateHistoricoItemDate`.

---

## 4. Contratos e Camadas de Software

### 4.1. Interface `TarefaHabitoRepository`
```dart
Future<bool> updateHistoricoItemDate({
  required String id,
  required DateTime newDate,
});
```

### 4.2. `AppwriteTarefaHabitoRepository`
Implementa o método atualizando a linha na tabela de histórico:
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

### 4.3. `DriftTarefaHabitoRepository`
1. Executa update no Drift SQLite.
2. Adiciona à fila offline.
3. Tenta sincronização remota via `remoteRepository`.
4. Em caso de sucesso remoto, remove da fila offline.

### 4.4. `HistoricoController`
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
    log('Erro ao atualizar data do histórico: $e');
    return false;
  }
}
```

---

## 5. Interface do Usuário e Interação (Design System)

### 5.1. Arrastar e Soltar no `SfCalendar`
- Atributos no `SfCalendar`:
  ```dart
  allowDragAndDrop: true,
  onDragEnd: _handleAppointmentDragEnd,
  ```
- Tratamento em `_handleAppointmentDragEnd(AppointmentDragEndDetails details)`:
  - Recupera o `Appointment` e o `dropTime`.
  - Se `dropTime` for válido e diferente do original, chama `Core.historicoController.updateHistoricoDate(...)`.
  - Exibe feedback com `SnackBar` utilizando as cores e tipografia do Design System.

### 5.2. Modal de Detalhes ao Tocar no Compromisso (`onTap`)
- Substituição do `_showDeleteDialog` por `_showHistoricoDetailsModal(BuildContext context, HistoricoItemModel item)`:
  - Implementado como `showModalBottomSheet` com cantos superiores arredondados (`AppRadius.roundedXl`) e fundo sereno.
  - **Cabeçalho:** Nome do item em destaque (`AppTypography.titleMedium`) e badge pastel com o tipo (`Hábito`, `Recaída` ou `Tarefa`).
  - **Info de Data/Hora:** Exibição elegante da data e horário atual da execução.
  - **Botão "Alterar data e horário":**
    - Executa `showDatePicker` com a data atual selecionada.
    - Se confirmado, executa `showTimePicker` com a hora atual selecionada.
    - Combina data e hora e chama `updateHistoricoDate`.
  - **Botão "Excluir registro":** abre confirmação de exclusão mantendo a ação segura existente.
  - **Botão "Cancelar" / Fechar.**

---

## 6. Estratégia de Testes

1. **Testes de Unidade (`test/repositories/`):**
   - `AppwriteTarefaHabitoRepository.updateHistoricoItemDate`: teste simulando chamada do `TablesDB.updateRow`.
   - `DriftTarefaHabitoRepository.updateHistoricoItemDate`: teste de atualização local no SQLite, enfileiramento na fila offline e envio para o repositório remoto.
2. **Testes de Controller (`test/app/capacitacao/tarefas_habitos/`):**
   - `HistoricoController.updateHistoricoDate`: verifica chamada ao repositório e recarga das tarefas/hábitos.
3. **Testes de Widget (`test/app/capacitacao/tarefas_habitos/`):**
   - `CalendarioPage`: teste de renderização dos compromissos, abertura do modal de detalhes ao tocar e verificação da presença do botão de alterar data e hora.

---

## 7. Conclusão
O design proposto atende integralmente à solicitação do usuário, suporta tanto arrastar e soltar quanto edição fina via seletor, respeita todos os preceitos de arquitetura offline-first e design pastel do PPVDigital, e garante retrocompatibilidade e integridade de dados.
