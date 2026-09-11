# Implementação: Menu de Configurações, Temas Pastel e Correção de Recorrência Infinita

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Adicionar menu de configurações na tela inicial (`HomePage`) após o login para alternar entre Dark e Light mode e selecionar entre 10 paletas pastéis do Design System com persistência local no SQLite, além de corrigir o bug e implementar alta performance com buffer de 24 ocorrências na Cloud Function Go de recorrência infinita.

**Architecture:** `ThemeController` com observables manuais do MobX registrado no `Core`, persistindo configurações de UI no Drift SQLite (`AppSettings`) e integrando dinamicamente ao `MaterialTheme` e `RootAppWidget` via `Observer`. Correção em Go da Cloud Function substituindo a consulta restritiva de hoje por um horizonte dinâmico de 24 ocorrências futuras com cache de checkpoint em `fimRecorrencia`.

**Tech Stack:** Flutter, MobX (manual), Drift SQLite, Go (Appwrite Functions SDK v5).

---

## Proposed Changes

### Componente 1: Design System e Persistência Local

#### [NEW] [app_theme_palette.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/design_system/app_theme_palette.dart)
- Enum `AppThemePalette` contendo as 10 opções:
  - `menta`, `lavanda`, `pessego`, `ceuSereno`, `salvia`, `rosaBlush`, `turquesa`, `ametista`, `baunilha`, `areia`.
  - Propriedades com cores primárias Light e Dark, rótulo em português e método `fromString(String?)`.
- Reexportado em `lib/design_system/design_system.dart`.

#### [MODIFY] [app_database.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/models/local/app_database.dart)
- Ajustar `clearAllUserData()` para não deletar chaves de configuração de tema (`theme_mode`, `theme_palette`):
  ```dart
  await (delete(appSettings)
    ..where((s) => s.key.isNotIn(['theme_mode', 'theme_palette']))).go();
  ```

---

### Componente 2: Estado Reativo do Tema (`ThemeController`)

#### [NEW] [theme_controller.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/controllers/theme_controller.dart)
- Controller MobX com observables manuais:
  - `Observable<ThemeMode> _themeMode`
  - `Observable<AppThemePalette> _palette`
  - `Future<void> loadSettings()`
  - `Future<void> setThemeMode(ThemeMode mode)`
  - `Future<void> setPalette(AppThemePalette palette)`

#### [MODIFY] [core.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/core.dart)
- Registrar `ThemeController` em `Core.initialize()` e expor getter `Core.themeController`.
- Chamar `loadSettings()` assincronamente durante a inicialização.

---

### Componente 3: MaterialTheme Dinâmico e Reatividade Global

#### [MODIFY] [theme.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/theme.dart)
- Atualizar `lightScheme([AppThemePalette? palette])` e `darkScheme([AppThemePalette? palette])` para utilizar as cores da paleta selecionada para os tokens primários (`primary`, `primaryContainer`, `onPrimary`, `onPrimaryContainer`, etc.) preservando as superfícies pastéis neutras.
- Atualizar `light([AppThemePalette? palette])` e `dark([AppThemePalette? palette])`.

#### [MODIFY] [root_app_widget.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/root_app_widget.dart)
- Envolver `MaterialApp.router` com `Observer` do MobX:
  - `themeMode: Core.themeController.themeMode`
  - `theme: theme.light(Core.themeController.palette)`
  - `darkTheme: theme.dark(Core.themeController.palette)`

---

### Componente 4: Interface do Usuário (`ConfiguracoesModalWidget` & `HomePage`)

#### [NEW] [configuracoes_modal_widget.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/app/home/widgets/configuracoes_modal_widget.dart)
- Modal Bottom Sheet desenvolvido estritamente com os tokens do Design System:
  - Seletor de Modo: `SegmentedButton<ThemeMode>` (Claro, Escuro, Sistema).
  - Seletor de Paleta: Grade ou lista com as 10 cores pastéis do Design System, preview de cor, nome amigável e indicador de seleção ativa.
  - Mudança instantânea em tempo real e gravação em SQLite.

#### [MODIFY] [home_page.dart](file:///home/wladimir/Documentos/Github/ppvdigital/lib/app/home/home_page.dart)
- Adicionar `IconButton(icon: Icon(Icons.settings_outlined))` nas `actions` da `AppBar` para abrir o `ConfiguracoesModalWidget`.

---

### Componente 5: Correção da Function Go de Recorrência Infinita

#### [MODIFY] [main.go](file:///home/wladimir/Documentos/Github/ppvdigital/functions/process_recurrent_transactions/main.go)
- Remover o bloco restritivo `todayTxRes` (linhas 180-212).
- Adicionar cálculo de horizonte móvel (`targetHorizon` de 24 ciclos para `dia`, `semana`, `mês`, `ano`).
- Checar `fimRecorrencia` da regra para pular regras já atualizadas em memória ($O(1)$).
- Loop de autocura: enquanto `latestDate.Before(targetHorizon)`, gerar novas transações e clonar divisões.
- Atualizar `fimRecorrencia = latestDate` na coleção `transacao_recorrencia`.

#### [MODIFY] [README.md](file:///home/wladimir/Documentos/Github/ppvdigital/functions/process_recurrent_transactions/README.md)
- Atualizar documentação explicando a esteira de 24 ocorrências com autocura e a otimização de performance via `fimRecorrencia`.

---

## Verification Plan

### Automated Tests
- `fvm flutter test test/unit/theme_database_test.dart` (testar persistência e `clearAllUserData`)
- `fvm flutter test test/unit/theme_controller_test.dart` (testar actions MobX, loadSettings e persistência)
- `fvm flutter test test/widget/configuracoes_modal_test.dart` (testar renderização e seleção no modal)
- `fvm flutter test test/app/home/home_page_settings_test.dart` (testar botão na HomePage e abertura do modal)
- `fvm flutter test` (verificar todos os testes do projeto mantendo 100% de sucesso)
- `fvm flutter analyze` (zero erros e zero warnings)

### Manual Verification
- Abrir a aplicação, entrar na `HomePage`, clicar no ícone de configurações da `AppBar`.
- Alternar entre os modos Claro, Escuro e Sistema e verificar a transição instantânea da interface.
- Selecionar diferentes paletas pastéis (ex.: Lavanda, Pêssego, Céu Sereno) e verificar a aplicação imediata das cores primárias.
- Fechar e reabrir o app para confirmar que a seleção foi preservada pelo SQLite.
