# PPVDigital - Projeto Pessoal de Vida (Digital)

![Flutter](https://img.shields.io/badge/Flutter-FVM%203.44.7-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart)
![MobX](https://img.shields.io/badge/State-MobX-orange)
![Drift](https://img.shields.io/badge/Database-Drift%20SQLite%20(v6)-lightgrey)
![Appwrite](https://img.shields.io/badge/Backend-Appwrite-FD366E?logo=appwrite)
![Design System](https://img.shields.io/badge/Design%20System-Pastel%20%26%20Leveza-7CB9A8)
![Tests](https://img.shields.io/badge/Tests-279%2F279%20Passed-brightgreen)

O **PPVDigital** é uma plataforma completa desenvolvida em Flutter (Web/Mobile) para planejamento pessoal, acompanhamento de hábitos, gestão de tarefas e controle financeiro pessoal e compartilhado. O projeto traz para o formato digital o conceito do **Projeto Pessoal de Vida (PPV)**, com foco em capacitação, acompanhamento de métricas e funcionamento offline transparente.

---

## 🏗️ Arquitetura da Aplicação

A aplicação adota uma arquitetura reativa, offline-first e modularizada por contextos de uso (`capacitacao`, `financas`, `tarefas_habitos`, `login`).

![Arquitetura da Aplicação](assets/images/arquitetura.png)

### Principais Tecnologias e Bibliotecas

- **Framework**: [Flutter](https://flutter.dev) (gerenciado via **FVM** - Flutter Version Manager).
- **Design System Pastel & Leveza**: Arquitetura centralizada de tokens de design (`lib/design_system/`) com paleta pastel serena (Menta, Lavanda, Pêssego), tipografia geométrica humanista ([Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)), cartela de 24 cores suaves personalizáveis (`AppColors.customizablePastelColors`), curvaturas acolhedoras (`AppRadius`) e sombras difusas (`AppShadows`), com governança documentada em [docs/design_system.md](docs/design_system.md). Conta com **Menu de Configurações de Temas** na tela inicial pós-login (`HomePage`) com alternância em tempo real entre **10 paletas pastéis oficiais** (`AppThemePalette`: Menta, Lavanda, Pêssego, Céu Sereno, Sálvia, Rosa Blush, Turquesa, Ametista, Baunilha, Areia) e **3 modos** (Claro, Escuro e Sistema), orquestrado por `ThemeController` (MobX manual) e persistido localmente no Drift SQLite (`AppSettings`), preservado no logout (`clearAllUserData()`).
- **Gerenciamento de Estado**: [MobX](https://pub.dev/packages/mobx) e `flutter_mobx` utilizando reatividade com instanciações manuais (`mobx.Observable`), getters com baixa alocação e mutações seguras via `mobx.runInAction()`.
- **Banco de Dados Local & Cache Offline**: [Drift](https://drift.simonbinder.eu/) (SQLite reativo **Schema v6** com índices compostos em colunas críticas como `remoteId`, `usuarioId`, `dataCompetencia`, `agendamento`), permitindo consultas ultrarrápidas sem dependência imediata de rede e isolamento atômico de dados por usuário (`clearAllUserData()`).
- **Backend & Backend-as-a-Service (BaaS)**: [Appwrite SDK](https://appwrite.io), gerenciando autenticação, sessões, persistência remota e **Appwrite Realtime (WebSockets)** escopado por usuário para sincronização instantânea inter-dispositivos.
- **Serverless Functions**: Função Go 1.26 (`functions/process_recurrent_transactions`) para processamento automatizado de transações recorrentes indeterminadas. Implementa **esteira móvel de 24 ocorrências futuras** com **autocura de lacunas** para qualquer periodicidade (`dia`, `semana`, `quinzenal`, `mês`, `ano`), e **filtro de alta performance em memória ($O(1)$)** via checkpoint na coluna `fimRecorrencia` para dispensar consultas adicionais ao banco em execuções rotineiras.
- **Arquitetura Híbrida de Sincronização**: Combinação de mutações REST API, canal Realtime Pub/Sub WebSocket para atualizações ativas, e **Delta Sync com Projeção Leve de IDs** (`Query.select(['$id'])`) para reconciliação de exclusões sem consumo desnecessário de tráfego de rede ao retomar o foco (`AppLifecycleState.resumed`).
- **Domínio e Tipagem Forte**: Enums tipados do Dart 3 (`TipoTransacao`, `TipoItem`, `TipoHabito`, `TipoRecorrencia`) e desacoplamento de regras puras com `RecorrenciaService` via *switch expressions*.
- **Roteamento Baseado em Arquivos**: [Routefly](https://github.com/wladrbarbosa/routefly) para navegação declarativa baseada na estrutura do sistema de arquivos.
- **Visualização de Dados**: `fl_chart`, `timeline_tile`, `flutter_animation_progress_bar` e `syncfusion_flutter_calendar`.

---

## 📋 Regras de Negócio e Módulos

### 💵 1. Módulo de Finanças

O módulo financeiro permite controlar contas, categorias, lançamentos individuais, transferências e despesas compartilhadas.

#### Tipos de Transação
- **Receita**: Incremente no saldo das contas afetadas.
- **Despesa**: Débito no saldo das contas afetadas.
- **Transferência**: Débito na conta de origem e crédito na conta de destino, com impacto neutro no patrimônio total.

#### Isolamento Estrito de Transações por Contas do Usuário
- Consultas locais (`getTransacoes`, `watchTransacoes`) no Drift SQLite filtram estritamente por contas pertencentes ao usuário autenticado (`t.contaId.isIn(userContaIds) | t.contaDestinoId.isIn(userContaIds)`), impedindo vazamento de dados locais entre contas não autorizadas.
- Eventos de Realtime WebSockets (`handleRealtimeEvent`) descartam automaticamente inserções/atualizações de transações cujas contas não pertençam ao usuário ativo.

#### Divisão por Pesos entre Contatos (`DivisaoTransacaoModel`)
- Suporta a divisão proporcional de uma despesa/receita entre múltiplos contatos.
- Cada divisão possui um `peso` relativo. A parcela de cada participante é calculada via:
  $$\text{Valor do Contato} = \text{Valor Total} \times \left( \frac{\text{Peso do Contato}}{\sum \text{Pesos}} \right)$$
- Se nenhuma divisão for cadastrada, o valor é atribuído 100% ao responsável pela conta.

#### Recorrência e Parcelamentos (`RecorrenciaService` & `TransacaoRecorrenciaModel`)
- Suporta frequências **diária**, **semanal**, **mensal** e **anual** calculadas pelo serviço desacoplado de domínio `RecorrenciaService`.
- Cálculo automático das datas de competência de cada parcela com tratamento para anos bissextos e bordas de meses.
- Permite número fixo de parcelas (`totalParcelas`) ou recorrência indeterminada (`fimRecorrencia`).
- Atualizações em série (`current_and_future` e `all`) suportam expansão dinâmica de parcelamento (criando automaticamente parcelas faltantes nos meses subsequentes) e redução (removendo parcelas excedentes), mantendo a integridade de datas, descrições, categorias, contas e divisões.

#### Métricas Mensais e Consolidação
- **`saldoAnterior`**: Soma das transações consolidadas ocorridas estritamente antes do mês selecionado.
- **`receitaMes` / `despesaMes`**: Soma das transações do mês exibido.
- **`saldoAtual`**: Saldo acumulado (Saldo Anterior + Receitas do Mês - Despesas do Mês).
- **Consolidação (`consolidada`)**: Transações consolidadas refletem o saldo real efetivado; transações não consolidadas alimentam as projeções financeiras.

#### Exportação de Transações (WhatsApp & CSV)
- Permite exportar os lançamentos da visualização corrente respeitando rigorosamente os filtros aplicados na tela (mês, tipo, conta, categoria e texto de busca).
- **Formatos Disponíveis**:
  - **Texto Amigável para WhatsApp**: Formatado com emojis, negrito padrão do WhatsApp, cabeçalho de filtros ativos e resumo de totais (Receitas, Despesas e Saldo Líquido).
  - **Planilha CSV**: Arquivo estruturado com delimitador `;`, escape de caracteres especiais e BOM UTF-8 (`\uFEFF`) para compatibilidade nativa com Microsoft Excel.
- **Opções de Estrutura**:
  - **Separar por data**: Agrupa os lançamentos cronologicamente por dia e exibe o saldo acumulado ao final de cada data.
  - **Somente transações**: Lista linear com resumo consolidado e totais ao final.
- **Ações**: Cópia instantânea para a área de transferência com feedback visual e download direto do arquivo `.csv` na Web e Mobile/Desktop.

---

### 🎯 2. Módulo de Tarefas e Hábitos

Acompanhamento do desenvolvimento pessoal através da criação e monitoramento de hábitos e execução de tarefas.

#### Hábitos Positivos vs. Hábitos Negativos
- **Hábitos Positivos (Construir)**: Hábitos com valores positivos que aumentam o progresso executado e possuem configuração de janelas de reinício e ciclos periódicos.
- **Hábitos Negativos (Parar / Abstinência)**: Hábitos destinados a interromper comportamentos indesejados.
  - Possuem valor multiplicador negativo (reduzem o progresso no `DashboardLogic`).
  - Utilizam o campo `metaVezes` para registrar a **Meta de dias sem praticar** (abstinência).
  - Cálculo automático de **dias sem praticar** baseado no intervalo entre o último registro de recaída no histórico (ou criação) e o dia atual.
  - **Visualização Visual Diferenciada**: Cards em cor contrastante (`Colors.deepOrange`), com indicador líquido que se inicia vazio (0%) e se preenche gradualmente com os dias sem praticar até atingir 100% na meta de dias.
  - **Registro de Recaída**: Botão de ação dedicado com ícone de alerta e diálogo de confirmação explicativo antes de registrar a recaída e reiniciar a contagem.
  - **Ordenação**: Suporte a ordenação dinâmica de hábitos por tipo (`Positivos / Negativos`).

#### Tarefas e Hábitos Arquivados (`arquivado`)
- Campo booleano `arquivado` suportado em Drift SQLite (Schema v5) e Appwrite API.
- Itens arquivados não aparecem na listagem padrão nem alimentam os cálculos do dashboard ativo.
- Disponível visualização dedicada de itens arquivados através de botão alternador na tela de listagem de hábitos e tarefas.

#### Janelas de Reinício e Frequência de Hábitos
- Configuração de ciclos de reinício por **dias**, **semanas**, **meses** ou **anos**.
- Extensão `toTarefaHabitoQtdModelList` calcula automaticamente o total de execuções dentro da janela ativa.
- **Métrica de Progresso**:
  $$\text{vezesPraticado} = \text{Quantidade de Históricos na Janela} \times \text{Valor Multiplicador}$$
- **Meta Atingida**: Hábito considerado concluído no ciclo quando $\text{vezesPraticado} \ge \text{metaVezes}$.

#### Matriz de Calendário, Histórico e Cache Reativo
- Matriz dinâmica de dias (35 ou 42 células) gerada pelo `CalendarioController` exibindo o preenchimento dos dias vizinhos.
- Histórico de execuções (`HistoricoItemModel`) registrado no banco local e sincronizado remotamente.
- **Reagendamento de Execuções no Calendário**: Suporte completo à alteração da data e horário de qualquer execução exibida na visualização de calendário (`CalendarioPage`), tanto via **arrastar e soltar (drag & drop)** diretamente na grade do `SfCalendar` quanto via **modal de detalhes** com seletores temáticos de data e horário (`showDatePicker` / `showTimePicker`), contando com atualização otimista instantânea no Drift SQLite, fila de sincronização offline e persistência remota no Appwrite via coluna `dataCriacao`.
- **Cache-First, Delta Sync & Realtime WebSockets**: Renderização instantânea dos hábitos e tarefas diretamente do Drift SQLite, com atualização em tempo real via WebSockets (`AppwriteRealtimeService`), reconciliação de itens excluídos remotamente e sincronização incremental em segundo plano filtrando registros alterados via `$updatedAt` e timestamps salvos em `AppSettings`.

#### Métricas e Gráficos do Dashboard (`DashboardLogic`)
- **Tempo Comprometido vs Disponível**:
  - **Tempo Disponível**: Capacidade total em minutos por ciclo:
    - **Dia**: $24\text{h} = 1.440\text{ min}$
    - **Semana**: $7 \times 24\text{h} = 10.080\text{ min}$
    - **Mês**: $\text{diasNoMês} \times 1.440\text{ min}$ (dinâmico: 28, 29, 30 ou 31 dias)
    - **Ano**: $\text{diasNoAno} \times 1.440\text{ min}$ ($525.600\text{ min}$ ou $527.040\text{ min}$ em anos bissextos)
  - **Tempo Previsto (Comprometido)**: Calculado exclusivamente sobre **hábitos** (`item.tipo == 'habito'`) com duração válida:
    $$\text{Minutos Base} = \frac{\text{duration} \times \text{metaVezes}}{\text{reiniciaEmQtd}}$$
    Convertido proporcionalmente para os 4 ciclos (Dia, Semana, Mês e Ano) de acordo com a frequência base do hábito.
  - **Tempo Executado**: Soma os minutos registrados em `HistoricoItemModel` dentro dos limites exatos do ciclo corrente (`startOfDay..endOfDay`, `startOfWeek..endOfWeek`, `startOfMonth..endOfMonth`, `startOfYear..endOfYear`).
- **% Meta por Categoria**:
  - **Metas**: Calculadas estritamente a partir de hábitos (tarefas não entram na meta).
  - **Executado**: Contabiliza execuções de hábitos e tarefas concluídas na categoria durante o ciclo (com execuções de hábitos negativos reduzindo o progresso).

---

### 🎨 3. Design System & Identidade Visual (Pastel & Leveza)

O PPVDigital adota um Design System proprietário com foco em leveza visual, conforto cognitivo e elegância através de tons pastéis suaves. A especificação completa encontra-se em [docs/design_system.md](docs/design_system.md).

#### Princípios e Tokens Principais (`lib/design_system/`)
- **Cores Pastéis (`AppColors`)**: Menta Pastel (`#7CB9A8`), Lavanda (`#9B9CD6`), Pêssego/Coral (`#F5B1A2`) e fundos arejados (`#F9FAFC` Light e `#16191F` Dark).
- **Cartela de Cores Personalizáveis (`AppColors.customizablePastelColors`)**: 24 tons pastéis exclusivos e balanceados para seleção do usuário ao criar ou editar categorias, hábitos, tarefas e contas financeiras.
- **Tipografia Geométrica Moderna**: Migração para a fonte [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) em títulos e corpos de texto.
- **Espaçamento e Curvaturas (`AppSpacing` & `AppRadius`)**: Grade proporcional de espaçamento (de 2 a 48 dp) e curvaturas generosas (`roundedMd`: 12 dp, `roundedLg`: 16 dp, `roundedXl`: 24 dp, `roundedFull`: 999 dp) para cartões, pílulas e modais.
- **Sombras Difusas de Baixa Opacidade (`AppShadows`)**: Sombras ultra-suaves (4% a 8% de opacidade) que eliminam o peso visual escuro e proporcionam sensação de flutuação natural.
- **Decorações Padronizadas (`AppDecorations`)**: Helpers para estilização consistente de cartões (`AppDecorations.card`), badges (`AppDecorations.badge`) e campos de entrada (`AppDecorations.input`).

---

### 💾 4. Módulo de Backup & Restauração de Dados (Manual e Google Drive)

Permite ao usuário salvaguardar e recuperar integralmente seu ecossistema pessoal (contas, categorias, transações passadas e futuras projetadas, divisões por contatos, hábitos, tarefas, históricos de execução e configurações de tema) com zero perda de dados.

- **Backup Manual (`.json`)**:
  - Exportação e download direto do arquivo de backup no formato JSON com assinatura criptográfica SHA-256 no cabeçalho para verificação de autenticidade e integridade.
  - Restauração assistida por diálogo interativo com leitura de resumo prévio, contadores de registros e opção de substituição limpa (*Clean Replacement*) ou mescla incremental (*Upsert*).
  - Suporte multiplataforma (Web via `dart:html` blob download / `FileReader` e Mobile/Desktop via I/O com cache em diretório de documentos).
- **Integração Automática com Google Drive**:
  - Autenticação OAuth2 restrita ao escopo mínimo de menor privilégio (`drive.file`), acessando exclusivamente os arquivos gerados pelo próprio PPVDigital.
  - Criação e reutilização automática de pasta dedicada no Drive (`PPVDigital_Backups`).
  - **Sincronização Diária em Segundo Plano**: Verificação periódica a cada 24 horas no ciclo de vida da aplicação (`AppLifecycleState.resumed`), realizando upload transparente sem travar ou bloquear a interface do usuário.
  - **Política de Retenção Móvel de 30 Dias**: Rotação automática de backups no Google Drive mantendo snapshots das últimas 30 datas e excluindo versões mais antigas para preservar espaço de armazenamento.
  - **Experiência Transparente para o Usuário Final**: Conexão simples e direta com um clique via OAuth2 nativo, sem exigir que o usuário final acesse o Google Cloud Console ou configure chaves técnicas. O Client ID pode ser fornecido no build via `--dart-define=GOOGLE_CLIENT_ID=...` ou herdado da configuração do ambiente. No Flutter Web, utiliza `authorizationClient.authorizeScopes` para integração moderna com `google_sign_in: 7.2.0`.
- **Cobertura Temporal Irrestrita (Finanças & Hábitos)**:
  - Extração paginada de todas as 10 coleções do usuário sem filtros de `dataCompetencia`, garantindo que transações do passado histórico, presente corrente e parcelas/recorrências futuras permaneçam 100% preservadas.
- **Integridade Referencial em 4 Fases**:
  - Processo de restauração orquestrado em etapas ordenadas para respeitar dependências de chaves estrangeiras:
    1. **Fase 1**: Contas, Categorias de Finanças e Categorias de Tarefas/Hábitos.
    2. **Fase 2**: Contatos e Modelos Base de Hábitos/Tarefas.
    3. **Fase 3**: Transações Financeiras e Históricos de Execução.
    4. **Fase 4**: Divisões de Transações Financeiras.
  - Limpeza atômica em ordem inversa de dependências no modo de substituição limpa, seguida de reset do cache local Drift SQLite e recarregamento reativo dos controllers.

---

### 🔑 5. Módulo de Autenticação e Isolamento de Sessão

- Gerenciamento de sessão via `LoginController` integrado ao Appwrite `Account`.
- Persistência e restauração offline do perfil do usuário em `Drift SQLite` (`AppSettings`) para acesso sem conexão à internet.
- **Isolamento de Cache e Reset Multi-Usuário**: Ao efetuar logout (`signOut`) ou ao autenticar um usuário com `userId` diferente do anterior no mesmo dispositivo, o app executa a limpeza atômica de todas as tabelas locais do Drift (`clearAllUserData()`), reseta os timestamps de sincronização (`last_..._sync_time`) e zera o estado em memória dos controllers. Isso garante que o novo usuário realize uma sincronização inicial completa a partir do Appwrite, evitando vazamento de dados locais ou listas vazias por filtros de delta sync obsoletos.
- Validação estrita de e-mail e requisitos mínimos de senha.

---

## 🛠️ Diretrizes Técnicas do Projeto (AGENTS.md)

Para garantir consistência e alto desempenho, a codebase obedece às seguintes regras fundamentais:

1. **Flutter Version Manager (FVM)**:
   - Todos os comandos do SDK do Flutter **devem** ser prefixados por `fvm`. Exemplo: `fvm flutter run`, `fvm flutter test`.
2. **Projeções em Relacionamentos do Appwrite API (`Query.select`)**:
   - **É proibido** combinar a wildcard raiz `'*'` com wildcards de relacionamento (ex: `'conta.*'`). A combinação causa o retorno nulo de atributos raízes no Appwrite. O repositório deve listar explicitamente todos os atributos necessários:
     ```dart
     Query.select([
       'descricao',
       'valor',
       'tipo',
       'dataCompetencia',
       'consolidada',
       'conta.*',
       'contaDestino.*',
     ])
     ```
3. **Integridade de Cache Offline no Drift SQLite**:
   - Consultas leves (*lightweight*) ou parciais não podem sobrescrever dados completos já armazenados nas tabelas do Drift.
4. **Sincronização Não-Bloqueante (UI/UX)**:
   - A sincronização em segundo plano exibe um indicativo discreto (`LinearProgressIndicator`) no topo da tela, sem bloquear a interação do usuário com overlays de carregamento.
5. **Governança do Design System Pastel & Leveza**:
   - Qualquer modificação de tela, widget ou novo componente deve consultar [docs/design_system.md](docs/design_system.md) e aplicar os tokens de `lib/design_system/`. Cores saturadas duras inline são estritamente proibidas.

---

## 🧪 Suíte de Testes Automatizados

O projeto conta com uma suíte de testes unitários e de integração validando todas as regras de negócio:

### Executando os Testes

Para rodar todos os testes automatizados da aplicação:

```bash
fvm flutter test
```

### Estrutura dos Arquivos de Teste (`test/`)

- `test/design_system/design_system_test.dart`: Testes unitários dos tokens de cores pastéis, espaçamentos, curvaturas, sombras e decorações visuais.
- `test/design_system/theme_test.dart`: Testes de integração do ThemeData com MaterialTheme (light e dark) e tipografia Plus Jakarta Sans.
- `test/business_logic/financas_business_test.dart`: Testes de cálculo de divisão por pesos, geração de datas recorrentes, transferências e resumos de saldo mensal.
- `test/business_logic/tarefas_habitos_business_test.dart`: Testes de janelas de reinício de hábitos, progresso de metas e matriz de calendário.
- `test/business_logic/login_business_test.dart`: Testes de validação de formulários e estados da sessão de autenticação.
- `test/business_logic/drift_cache_sync_test.dart`: Teste automatizado que varre a codebase para garantir que nenhuma consulta viole a regra do `Query.select()` do Appwrite, e teste de preservação do cache local Drift.
- `test/drift_financas_repository_test.dart`: Testes de integração das operações de finanças e realtime no banco SQLite local.
- `test/drift_tarefa_habito_repository_test.dart`: Testes de integração das operações de tarefas/hábitos e realtime no banco SQLite local.
- `test/unit/transaction_isolation_test.dart`: Testes unitários de isolamento de consultas e streams de transações por contas de usuário e descarte de eventos realtime de terceiros.
- `test/unit/negative_habits_test.dart`: Testes unitários do impacto negativo de hábitos no progresso do dashboard e distribuição de atenção.
- `test/unit/arquivado_tarefas_habitos_test.dart`: Testes unitários de serialização e persistência do campo `arquivado` em SQLite (v5).
- `test/unit/user_switch_cache_test.dart`: Testes unitários de isolamento multi-usuário, limpeza atômica do SQLite e reset completo de controllers MobX.
- `test/unit/theme_database_test.dart`: Testes unitários do enum `AppThemePalette` (10 paletas pastéis) e da preservação de `theme_mode` e `theme_palette` em `clearAllUserData()` no Drift SQLite.
- `test/unit/theme_controller_test.dart`: Testes unitários do `ThemeController` (MobX manual), reatividade de `setThemeMode`, `setPalette`, carregamento do SQLite com fallback seguro e injeção no `Core`.
- `test/widget/root_app_theme_test.dart`: Teste de widget cobrindo a reatividade global do `RootAppWidget` envolto em MobX `Observer`.
- `test/widget/configuracoes_modal_test.dart`: Testes de widget do `ConfiguracoesModalWidget` (SegmentedButton de 3 modos, 10 cartões pastéis do Design System e seção de Backup/Google Drive).
- `test/app/home/home_page_settings_test.dart`: Teste de integração do botão de configurações na AppBar da `HomePage` e abertura do modal.
- `test/unit/models/backup_payload_model_test.dart`: Testes unitários do modelo `BackupPayloadModel` (serialização, contadores de registros, parsing e validação criptográfica de checksum SHA-256).
- `test/unit/services/backup_service_test.dart`: Testes unitários do `BackupService` (extração paginada das 10 coleções, integridade temporal irrestrita com dados passados, presentes e futuros e geração de checksum).
- `test/unit/services/restore_service_test.dart`: Testes unitários do `RestoreService` (restauração segura em 4 fases, integridade referencial, validação de hash, modos clean replacement e upsert, e isolamento de cache Drift).
- `test/unit/services/google_drive_backup_service_test.dart`: Testes unitários do `GoogleDriveBackupService` (fluxos de upload, download, listagem, rotação de retenção de 30 dias e autenticação OAuth2 drive.file).
- `test/unit/controllers/backup_controller_test.dart`: Testes unitários do `BackupController` (gerenciamento de estado com observables manuais MobX, verificação de 24h e integração de backup/restauração manual e Drive).
- `test/widget/backup_restore_dialog_test.dart`: Testes de widget dos diálogos `BackupRestoreDialog` (progresso em tempo real, confirmação detalhada de registros e listagem/seleção de backups do Drive).
- `functions/process_recurrent_transactions/main_test.go`: Testes unitários da função Serverless Go (parsing de datas ISO, incremento de intervalos de recorrência e autocura de esteira de 24 ocorrências).
- `test/widget_test.dart`: Teste de fumaça de instanciação de widgets.

---

## 🚀 Como Executar o Projeto Localmente

### Pré-requisitos
1. [Flutter SDK](https://flutter.dev) (gerenciado via [FVM](https://fvm.app/)).
2. FVM instalado globalmente (`dart pub global activate fvm`).
3. Instância configurada do [Appwrite](https://appwrite.io) (ou credenciais `.env`).

### Passo a Passo

1. **Clonar o Repositório**:
   ```bash
   git clone https://github.com/wladrbarbosa/ppvdigital.git
   cd ppvdigital
   ```

2. **Instalar Dependências**:
   ```bash
   fvm flutter pub get
   ```

3. **Gerar Códigos (Drift e Roteamento)**:
   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configurar Variáveis de Ambiente**:
   Copie o arquivo `.env.example` para `.env` e preencha o Endpoint e Project ID do Appwrite:
   ```env
   APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
   APPWRITE_PROJECT_ID=seu_project_id
   ```

5. **Executar a Aplicação**:
   - **No Navegador (Web)**:
     ```bash
     fvm flutter run -d chrome
     ```
   - **No Dispositivo Móvel / Emulador**:
     ```bash
     fvm flutter run
     ```

---

## 📦 Deploy para Produção (Web)

O projeto inclui scripts automatizados de deploy em PowerShell e Bash para compilação PWA / Web:

- **Linux / macOS**:
  ```bash
  chmod +x deploy_web.sh
  ./deploy_web.sh
  ```
- **Windows (PowerShell)**:
  ```powershell
  .\deploy_web.ps1
  ```

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
