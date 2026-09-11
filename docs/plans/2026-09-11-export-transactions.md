# Exportação de Transações (WhatsApp & CSV) Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Adicionar funcionalidade de exportação da visualização atual de transações (com filtros e busca aplicados) no seletor de mês, com suporte a texto formatado para WhatsApp e arquivo CSV, nos modos agrupado por data com saldo acumulado ou linear com totais.

**Architecture:** Serviço desacoplado `TransactionExportService` para lógica pura de formatação e download multiplataforma, diálogo modal responsivo `ExportarTransacoesDialog` com pré-visualização em tempo real conforme tokens do Design System Pastel & Leveza, e botão de ação integrado ao `SeletorMesWidget` em `FinancasLayout`.

**Tech Stack:** Flutter 3.x, Dart 3.x, MobX, Design System Pastel & Leveza (`lib/design_system/`), Clipboard API (`package:flutter/services.dart`), Universal Web/IO file download.

---

### Task 1: Serviço de Formatação WhatsApp e CSV (`TransactionExportService`)

**Files:**
- Create: `lib/app/capacitacao/financas/services/transaction_export_service.dart`
- Test: `test/unit/transaction_export_service_test.dart`

**Step 1: Escrever teste falhando para formatação WhatsApp e CSV**
- Criar `test/unit/transaction_export_service_test.dart` cobrindo:
  - Formato WhatsApp agrupado por data com saldos diários acumulados.
  - Formato WhatsApp linear com totais gerais.
  - Formato CSV delimitado por `;` com BOM `\uFEFF`, escaping de aspas e linhas de total.
  - Tratamento de listas vazias e transações com divisões/valores negativos.

**Step 2: Executar teste para verificar falha**
- Executar: `fvm flutter test test/unit/transaction_export_service_test.dart`
- Esperado: FAIL (classe ou métodos inexistentes).

**Step 3: Implementar código mínimo em `TransactionExportService`**
- Criar `lib/app/capacitacao/financas/services/transaction_export_service.dart` com:
  - `formatWhatsApp({required List<TransacaoModel> transactions, required bool groupByDateWithBalance, Map<String, double>? saldosDiarios, required DateTime currentMonth, String? filterSummary})`
  - `formatCsv({required List<TransacaoModel> transactions, required bool groupByDateWithBalance, Map<String, double>? saldosDiarios, required DateTime currentMonth})`

**Step 4: Executar teste para verificar sucesso**
- Executar: `fvm flutter test test/unit/transaction_export_service_test.dart`
- Esperado: PASS.

**Step 5: Commit**
- Executar: `git add lib/app/capacitacao/financas/services/transaction_export_service.dart test/unit/transaction_export_service_test.dart && git commit -m "feat(financas): criar TransactionExportService com formatação WhatsApp e CSV"`

---

### Task 2: Download Multiplataforma e Manipulação de Arquivo CSV

**Files:**
- Modify: `lib/app/capacitacao/financas/services/transaction_export_service.dart`
- Create/Modify: `lib/app/capacitacao/financas/services/file_download_helper.dart` (ou condicional Web/IO)
- Test: `test/unit/transaction_export_service_test.dart`

**Step 1: Escrever teste para disparo e geração do arquivo CSV**
- Adicionar casos de teste verificando nome do arquivo gerado (ex.: `transacoes_2026_09.csv`) e conteúdo codificado.

**Step 2: Implementar helper de download multiplataforma**
- Suporte para Web (usando `dart:html` ou âncora/blob segura) e Mobile/Desktop (usando `path_provider` para salvar e retornar o caminho).

**Step 3: Executar testes**
- Executar: `fvm flutter test test/unit/transaction_export_service_test.dart`
- Esperado: PASS.

**Step 4: Commit**
- Executar: `git add lib/app/capacitacao/financas/services/ test/unit/transaction_export_service_test.dart && git commit -m "feat(financas): adicionar helper de download multiplataforma de CSV"`

---

### Task 3: Diálogo Modal de Exportação (`ExportarTransacoesDialog`)

**Files:**
- Create: `lib/app/capacitacao/financas/widgets/exportar_transacoes_dialog.dart`
- Test: `test/widget/exportar_transacoes_dialog_test.dart`

**Step 1: Escrever teste de widget falhando**
- Testar:
  - Renderização dos seletores de formato (WhatsApp e CSV).
  - Renderização dos seletores de modo (Data com saldo acumulado vs Somente transações).
  - Atualização do preview ao alternar seletores.
  - Clique em "Copiar" (chamando `Clipboard`).
  - Visibilidade e clique no botão de download CSV.

**Step 2: Executar teste para verificar falha**
- Executar: `fvm flutter test test/widget/exportar_transacoes_dialog_test.dart`
- Esperado: FAIL.

**Step 3: Implementar `ExportarTransacoesDialog`**
- Usar tokens do Design System (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppDecorations`).
- Incluir `SegmentedButton` ou Chips para formatos e opções.
- Caixa de preview scrollável (`maxHeight: 180dp`).
- Ações: Copiar (com SnackBar) e Baixar CSV.

**Step 4: Executar testes de widget**
- Executar: `fvm flutter test test/widget/exportar_transacoes_dialog_test.dart`
- Esperado: PASS.

**Step 5: Commit**
- Executar: `git add lib/app/capacitacao/financas/widgets/exportar_transacoes_dialog.dart test/widget/exportar_transacoes_dialog_test.dart && git commit -m "feat(financas): implementar widget ExportarTransacoesDialog"`

---

### Task 4: Integração no `SeletorMesWidget`

**Files:**
- Modify: `lib/app/capacitacao/financas/widgets/seletor_mes_widget.dart`
- Test: `test/widget/seletor_mes_widget_test.dart`

**Step 1: Escrever teste falhando para o botão de exportar no `SeletorMesWidget`**
- Testar se o `IconButton` de exportação está visível quando `onExportPressed` é fornecido e se o toque dispara a callback.

**Step 2: Executar teste**
- Executar: `fvm flutter test test/widget/seletor_mes_widget_test.dart`
- Esperado: FAIL.

**Step 3: Implementar botão de exportação no `SeletorMesWidget`**
- Adicionar parâmetro `final VoidCallback? onExportPressed;`.
- Renderizar `IconButton(icon: const Icon(Icons.share_outlined, size: 20), tooltip: 'Exportar transações', onPressed: onExportPressed)`.

**Step 4: Executar teste**
- Executar: `fvm flutter test test/widget/seletor_mes_widget_test.dart`
- Esperado: PASS.

**Step 5: Commit**
- Executar: `git add lib/app/capacitacao/financas/widgets/seletor_mes_widget.dart test/widget/seletor_mes_widget_test.dart && git commit -m "feat(financas): adicionar botão de exportar no SeletorMesWidget"`

---

### Task 5: Conexão Final no `FinancasLayout`

**Files:**
- Modify: `lib/app/capacitacao/financas/financas_layout.dart`
- Test: `test/widget/financas_export_integration_test.dart`

**Step 1: Conectar `onExportPressed` no `SeletorMesWidget` dentro de `FinancasLayout`**
- Passar callback que abre `ExportarTransacoesDialog` com:
  - `transactions: filteredTransList`
  - `saldosDiarios: saldosDiarios`
  - `currentMonth: _appliedMonth`
  - `filterSummary: _obterResumoFiltros()`

**Step 2: Escrever teste de integração de widget**
- Testar clique no botão de exportar dentro do fluxo de `FinancasLayout`.

**Step 3: Executar teste**
- Executar: `fvm flutter test test/widget/financas_export_integration_test.dart`
- Esperado: PASS.

**Step 4: Commit**
- Executar: `git add lib/app/capacitacao/financas/financas_layout.dart test/widget/financas_export_integration_test.dart && git commit -m "feat(financas): integrar diálogo de exportação no FinancasLayout"`

---

### Task 6: Verificação Global, Cobertura (~100%) e Documentação

**Files:**
- Modify: `README.md`
- Modify: `docs/plans/task.md`

**Step 1: Executar análise estática**
- Executar: `fvm flutter analyze`
- Esperado: 0 errors, 0 warnings.

**Step 2: Executar suíte completa de testes**
- Executar: `fvm flutter test`
- Esperado: Todos os testes passando sem quebras.

**Step 3: Atualizar documentação e task list**
- Atualizar `README.md` com a nova funcionalidade de exportação de transações.
- Atualizar `docs/plans/task.md` marcando as etapas como concluídas.

**Step 4: Commit final**
- Executar: `git add README.md docs/plans/task.md && git commit -m "docs: documentar funcionalidade de exportação de transações e finalizar checklist"`
