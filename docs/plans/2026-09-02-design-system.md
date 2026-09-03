# Design System Pastel & Leveza Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Implementar o Design System com paleta pastel e ar de leveza no Flutter, integrar ao tema global, adequar componentes existentes e estabelecer documentação e regras contínuas de governança para qualquer alteração futura de layout.

**Architecture:** Módulo centralizado de tokens em `lib/design_system/` desacoplado e reutilizável, integrado ao `MaterialTheme` e `ThemeData` em `lib/theme.dart`, com tipografia moderna `Plus Jakarta Sans` em `lib/util.dart`, componentes existentes chave refatorados para consumir os novos tokens, e diretrizes de governança registradas em `docs/design_system.md`, `.agents/AGENTS.md` e `README.md`.

**Tech Stack:** Flutter, Material 3, Google Fonts (`Plus Jakarta Sans`), Unit Testing (`package:flutter_test`).

---

### Task 1: Criar Módulo de Tokens do Design System (`lib/design_system/`)

**Files:**
- Create: `lib/design_system/app_colors.dart`
- Create: `lib/design_system/app_spacing.dart`
- Create: `lib/design_system/app_radius.dart`
- Create: `lib/design_system/app_shadows.dart`
- Create: `lib/design_system/app_typography.dart`
- Create: `lib/design_system/app_decorations.dart`
- Create: `lib/design_system/design_system.dart`
- Test: `test/design_system/design_system_test.dart`

**Step 1: Escrever teste unitário de tokens**
Criar `test/design_system/design_system_test.dart` validando que as cores pastéis, espaçamentos, raios e sombras estão definidos com contraste e integridade adequados.

**Step 2: Executar teste para verificar falha (vermelho)**
Run: `fvm flutter test test/design_system/design_system_test.dart`
Expected: FAIL (arquivos ainda não criados).

**Step 3: Implementar tokens do Design System**
Criar os arquivos de tokens em `lib/design_system/` com a paleta pastel suave, espaçamentos escalonados, raios arredondados e sombras difusas.

**Step 4: Executar teste para verificar aprovação (verde)**
Run: `fvm flutter test test/design_system/design_system_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/design_system/ test/design_system/
git commit -m "feat(design-system): implementar tokens centrais de cores pastéis, espaçamento e curvaturas"
```

---

### Task 2: Integrar Design System ao ThemeData Global e Tipografia

**Files:**
- Modify: `lib/theme.dart`
- Modify: `lib/util.dart`
- Test: `test/design_system/theme_test.dart`

**Step 1: Escrever teste unitário para o ThemeData pastel**
Criar `test/design_system/theme_test.dart` testando que `MaterialTheme.light()` e `MaterialTheme.dark()` aplicam os esquemas pastéis e estilos de componentes padrão.

**Step 2: Executar teste para verificar falha**
Run: `fvm flutter test test/design_system/theme_test.dart`
Expected: FAIL.

**Step 3: Atualizar `lib/theme.dart` e `lib/util.dart`**
Configurar `ColorScheme.light()` e `ColorScheme.dark()` com `AppColors`, aplicar `CardTheme`, `AppBarTheme`, `ElevatedButtonTheme`, `DialogTheme`, e migrar a tipografia de `Acme`/`Akaya Kanadaka` para `Plus Jakarta Sans`.

**Step 4: Executar testes de tema**
Run: `fvm flutter test test/design_system/theme_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/theme.dart lib/util.dart test/design_system/theme_test.dart
git commit -m "feat(theme): integrar tokens pastéis e tipografia Plus Jakarta Sans ao ThemeData global"
```

---

### Task 3: Adequar Componentes Existentes e Seletores de Cores Personalizáveis

**Files:**
- Modify: `lib/app/capacitacao/tarefas_habitos/tarefas_habitos_layout.dart`
- Modify: `lib/app/capacitacao/criar_editar_categoria_page.dart`
- Modify: `lib/app/capacitacao/criar_editar_categoria_transacao_page.dart`
- Modify: `lib/app/capacitacao/tarefas_habitos/widgets/tarefa_habito_card_widget.dart`
- Modify: `lib/app/capacitacao/financas/widgets/seletor_mes_widget.dart`
- Modify: `lib/app/home/home_page.dart`
- Test: `test/design_system/design_system_test.dart`

**Step 1: Adequar seletores de cores personalizáveis pelo usuário**
Atualizar `tarefas_habitos_layout.dart`, `criar_editar_categoria_page.dart` e `criar_editar_categoria_transacao_page.dart` para utilizarem `AppColors.customizablePastelColors` (24 opções ricas, suaves e elegantes), permitindo total liberdade de customização ao usuário sem perder o alinhamento com a leveza do Design System.

**Step 2: Ajustar `tarefa_habito_card_widget.dart`**
Substituir cores saturadas duras por badges pastéis, bordas delicadas (`AppColors.borderLight`) e sombras difusas.

**Step 3: Ajustar `seletor_mes_widget.dart`**
Adotar curvaturas `AppRadius.full`, bordas e tons de destaque pastéis.

**Step 4: Ajustar `home_page.dart`**
Harmonizar os cards de módulos com as cores pastéis do Design System.

**Step 5: Executar testes da suíte para garantir não-regressão**
Run: `fvm flutter test`
Expected: PASS.

**Step 6: Commit**
```bash
git add lib/app/capacitacao/ lib/app/home/
git commit -m "refactor(ui): adequar seletores de cores personalizáveis e componentes ao design system pastel"
```

---

### Task 4: Governança, Regras no AGENTS.md e Documentação

**Files:**
- Create: `docs/design_system.md`
- Modify: `.agents/AGENTS.md`
- Modify: `.agent/AGENTS.md`
- Modify: `README.md`

**Step 1: Criar `docs/design_system.md`**
Documentar especificações completas, guia visual, paleta hex, tokens tipográficos, espaçamento, curvaturas e exemplos de componentes.

**Step 2: Atualizar `.agents/AGENTS.md` e `.agent/AGENTS.md`**
Adicionar a nova regra mandatória: qualquer alteração de layout ou criação de tela DEVE consultar `docs/design_system.md` e aplicar os tokens de cores pastéis, tipografia e espaçamento.

**Step 3: Atualizar `README.md`**
Adicionar seção do Design System Pastel e instruções de uso.

**Step 4: Commit**
```bash
git add docs/design_system.md .agents/AGENTS.md .agent/AGENTS.md README.md
git commit -m "docs(design-system): registrar guia completo e estabelecer regra mandatória de governança nos AGENTS.md"
```

---

### Task 5: Verificação Global de Cobertura e Análise Estática

**Files:**
- Modify: `docs/plans/task.md`

**Step 1: Executar análise estática**
Run: `fvm flutter analyze`
Expected: No issues found.

**Step 2: Executar suíte completa de testes com cobertura**
Run: `fvm flutter test --coverage`
Expected: 100% de testes aprovados sem regressões.

**Step 3: Atualizar `docs/plans/task.md`**
Marcar todas as tarefas como concluídas.

**Step 4: Commit final**
```bash
git add docs/plans/task.md
git commit -m "chore: concluir implementação e governança do design system pastel"
```
