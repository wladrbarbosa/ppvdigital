# Especificação de Design: Menu de Configurações de Temas Pastel e Correção de Recorrência Infinita

**Data**: 11 de Setembro de 2026  
**Status**: Aprovado  
**Autores**: DeepMind Antigravity & Wladimir Barbosa  

---

## 1. Visão Geral e Objetivos

Este documento especifica o design técnico para duas demandas complementares no ecossistema Seapruma (PPVDigital):

1. **Menu de Configurações e Temas Pastel na Tela Inicial (`HomePage`)**:
   - Adição de um botão de configurações na `AppBar` da `HomePage` após o login.
   - Apresentação em modal bottom sheet aderente aos tokens do Design System (`AppRadius.roundedXl`, `AppSpacing`, `AppDecorations`, `AppColors`).
   - Suporte à alternância entre **Modo Claro**, **Modo Escuro** e **Automático (Sistema)**.
   - Suporte à seleção entre **10 Paletas Pastéis** harmoniosas extraídas do Design System oficial.
   - Persistência das preferências locais no banco de dados Drift SQLite (`AppSettings`), preservadas durante o logout em `clearAllUserData()`.
   - Reatividade instantânea no aplicativo inteiro através de MobX manual integrado a `RootAppWidget`.

2. **Correção de Lógica e Alta Performance na Function de Recorrência Infinita**:
   - Correção do bug na Cloud Function Go (`functions/process_recurrent_transactions/main.go`), onde a restrição de data de hoje (`todayTxRes`) causava o aborto prematuro de todas as 14 execuções anteriores sem criar transações.
   - Implementação de um algoritmo de **Esteira de 24 Ocorrências Futuras (Buffer Dinâmico com Autocura)**, compatível com qualquer periodicidade (`dia`, `semana`, `quinzenal`, `mês`, `ano`).
   - Otimização de performance extrema: uso do campo `fimRecorrencia` em `transacao_recorrencia` como checkpoint para evitar consultas desnecessárias na coleção de transações nas execuções rotineiras da Cron.

---

## 2. Frente 1: Menu de Configurações e Temas do Design System

### 2.1. Cartela das 10 Paletas Pastéis

Baseadas em `lib/design_system/app_colors.dart` e `docs/design_system.md`:

| # | Paleta | Cor Primária Light | Cor Primária Dark | Significado / Propósito |
|---|---|---|---|---|
| 1 | **Menta Pastel** | `#7CB9A8` | `#9FD3C5` | Padrão Seapruma (Frescor, clareza e leveza) |
| 2 | **Lavanda Suave** | `#A5A6D6` | `#C1C2EB` | Serenidade, calma e foco |
| 3 | **Pêssego Pastel** | `#F5B1A2` | `#F9CECE` | Aconchego e calor humano |
| 4 | **Céu Sereno** | `#97C8EB` | `#B5DBF2` | Clareza mental e amplitude |
| 5 | **Sálvia Pastel** | `#95B8A2` | `#ADC7B6` | Equilíbrio e conexão natural |
| 6 | **Rosa Blush** | `#F4ACB7` | `#FAC6CE` | Delicadeza, afeto e cuidado |
| 7 | **Turquesa Suave** | `#80CED7` | `#9FDDE4` | Fluidez e energia sutil |
| 8 | **Ametista Claro** | `#CDB4DB` | `#DDC7E7` | Inspiração, espiritualidade e intuição |
| 9 | **Baunilha Suave** | `#F6E7B0` | `#F9ECC7` | Luminosidade, acolhimento e otimismo |
| 10 | **Areia Suave** | `#D8D4D0` | `#E5E2DF` | Minimalismo orgânico e neutralidade |

### 2.2. Modelagem e Controller (`ThemeController`)

Seguindo estritamente a **Regra 3 do AGENTS.md (Observables manuais)**:

```dart
enum AppThemePalette {
  menta('menta', 'Menta Pastel', Color(0xFF7CB9A8), Color(0xFF9FD3C5)),
  lavanda('lavanda', 'Lavanda Suave', Color(0xFFA5A6D6), Color(0xFFC1C2EB)),
  pessego('pessego', 'Pêssego Pastel', Color(0xFFF5B1A2), Color(0xFFF9CECE)),
  ceuSereno('ceuSereno', 'Céu Sereno', Color(0xFF97C8EB), Color(0xFFB5DBF2)),
  salvia('salvia', 'Sálvia Pastel', Color(0xFF95B8A2), Color(0xFFADC7B6)),
  rosaBlush('rosaBlush', 'Rosa Blush', Color(0xFFF4ACB7), Color(0xFFFAC6CE)),
  turquesa('turquesa', 'Turquesa Suave', Color(0xFF80CED7), Color(0xFF9FDDE4)),
  ametista('ametista', 'Ametista Claro', Color(0xFFCDB4DB), Color(0xFFDDC7E7)),
  baunilha('baunilha', 'Baunilha Suave', Color(0xFFF6E7B0), Color(0xFFF9ECC7)),
  areia('areia', 'Areia Suave', Color(0xFFD8D4D0), Color(0xFFE5E2DF));

  const AppThemePalette(this.id, this.label, this.primaryLight, this.primaryDark);
  final String id;
  final String label;
  final Color primaryLight;
  final Color primaryDark;
}
```

- **`ThemeController`**:
  - `final mobx.Observable<ThemeMode> _themeMode`
  - `final mobx.Observable<AppThemePalette> _palette`
  - `Future<void> loadSettings()`: lê `theme_mode` e `theme_palette` de `Core.database.getSetting`.
  - `Future<void> setThemeMode(ThemeMode mode)`: atualiza observable e persiste em SQLite.
  - `Future<void> setPalette(AppThemePalette palette)`: atualiza observable e persiste em SQLite.
  - Registrado em `Core.initialize` e exposto como `Core.themeController`.

### 2.3. Integração com `MaterialTheme` e `RootAppWidget`

- Em `lib/theme.dart`, o método `lightScheme(AppThemePalette palette)` e `darkScheme(AppThemePalette palette)` passa a derivar `primary`, `primaryContainer`, `surfaceTint`, etc., com base na paleta selecionada, mantendo os tons neutros pastéis do Seapruma nas superfícies e fundos.
- No `RootAppWidget`, o build é envolvido por `Observer(builder: (context) { ... })`, passando ao `MaterialApp.router`:
  - `themeMode: Core.themeController.themeMode`
  - `theme: theme.light(Core.themeController.palette)`
  - `darkTheme: theme.dark(Core.themeController.palette)`

### 2.4. Preservação em `AppDatabase.clearAllUserData()`

O método `clearAllUserData()` no Drift SQLite é ajustado para:
```dart
await (delete(appSettings)
  ..where((s) => s.key.isNotIn(['theme_mode', 'theme_palette']))).go();
```
Garantindo que a personalização do usuário não seja perdida ao efetuar logout.

### 2.5. Componente de UI: `ConfiguracoesModalWidget`

- Aberto a partir de `IconButton(icon: Icon(Icons.settings_outlined))` na `AppBar` da `HomePage`.
- Estruturado como um Bottom Sheet com cantos `AppRadius.roundedXl`:
  - Seletor de modo com `SegmentedButton<ThemeMode>` (ícones de Sol, Lua e Engrenagem/Sistema).
  - Grade ou lista responsiva das 10 paletas, contendo amostra de cor, título amigável e indicador de seleção ativo nos tokens do Design System.

---

## 3. Frente 2: Correção e Alta Performance na Function de Recorrência Infinita

### 3.1. Causa Raiz do Problema
O código anterior consultava:
```go
todayTxRes, err := dbService.ListDocuments(..., StartsWith("dataCompetencia", startOfDay))
if len(todayDocuments) == 0 {
    // Skipping...
    return
}
```
Isso causava a rejeição de 100% das execuções porque transações de recorrência têm datas de vencimento arbitrárias e o cron não roda no instante exato de cada uma delas. Além disso, o Flutter já cria 24 parcelas no início.

### 3.2. Arquitetura do Buffer Dinâmico com Autocura (24 Ocorrências)

1. **Horizonte Alvo**:
   Dado `now = time.Now().UTC()`, calcula-se o marco de tempo que compreende 24 ciclos no futuro:
   - `dia`: `now.AddDate(0, 0, 24 * freq)`
   - `semana`: `now.AddDate(0, 0, 24 * 7 * freq)`
   - `mês` / `mes`: `now.AddDate(0, 24 * freq, 0)`
   - `ano`: `now.AddDate(24 * freq, 0, 0)`

2. **Filtro de Performance via `fimRecorrencia`**:
   - Ao ler cada regra de recorrência, se `fimRecorrencia` já estiver gravado e `fimRecorrencia >= targetHorizon`, a regra é ignorada imediatamente em memória ($O(1)$).
3. **Autocura de Lacunas**:
   - Se `fimRecorrencia` for nulo ou anterior ao horizonte:
     - Busca a última transação existente (`orderDesc("dataCompetencia")`, `limit(1)`).
     - Executa o loop:
       ```go
       for latestDate.Before(targetHorizon) {
           nextDate = calcularProximaData(latestDate, tipoRecorrencia, freq)
           clonarTransacao(latestTx, nextDate)
           clonarDivisoes(latestTxID, newTxID)
           latestDate = nextDate
       }
       ```
     - Se existirem 20 ocorrências, o loop gerará 4 ocorrências (21, 22, 23 e 24). Se houver 15, gerará 9. Se já houver 24, gerará 0.
4. **Checkpoint**:
   - Atualiza `fimRecorrencia = latestDate` na coleção `transacao_recorrencia`.

---

## 4. Estratégia de Testes e Validação

1. **Testes de Unidade Dart**:
   - `test/unit/theme_controller_test.dart`:
     - Testar inicialização com valores padrão.
     - Testar carregamento de `AppSettings` no Drift SQLite.
     - Testar `setThemeMode` e persistência.
     - Testar `setPalette` e persistência.
     - Testar que `clearAllUserData` preserva as chaves de tema.
2. **Testes de Widget Dart**:
   - `test/widget/configuracoes_modal_test.dart`:
     - Renderização do modal com 10 paletas e 3 modos.
     - Seleção de novo tema e notificação reativa no MobX.
   - `test/widget/home_page_settings_test.dart`:
     - Testar presença do ícone na `HomePage` e abertura do modal.
3. **Validação do Go**:
   - Validação da compilação e lógica com `go test` / `go vet` ou script de verificação no módulo Go.
4. **Garantia de Qualidade**:
   - Execução de `fvm flutter analyze` (zero erros e zero warnings).
   - Execução de `fvm flutter test` mantendo 100% dos testes passando.
