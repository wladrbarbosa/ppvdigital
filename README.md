# PPVDigital - Projeto Pessoal de Vida (Digital)

![Flutter](https://img.shields.io/badge/Flutter-FVM%203.44.7-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart)
![MobX](https://img.shields.io/badge/State-MobX-orange)
![Drift](https://img.shields.io/badge/Database-Drift%20SQLite-lightgrey)
![Appwrite](https://img.shields.io/badge/Backend-Appwrite-FD366E?logo=appwrite)
![Tests](https://img.shields.io/badge/Tests-26%2F26%20Passed-brightgreen)

O **PPVDigital** é uma plataforma completa desenvolvida em Flutter (Web/Mobile) para planejamento pessoal, acompanhamento de hábitos, gestão de tarefas e controle financeiro pessoal e compartilhado. O projeto traz para o formato digital o conceito do **Projeto Pessoal de Vida (PPV)**, com foco em capacitação, acompanhamento de métricas e funcionamento offline transparente.

---

## 🏗️ Arquitetura da Aplicação

A aplicação adota uma arquitetura reativa, offline-first e modularizada por contextos de uso (`capacitacao`, `financas`, `tarefas_habitos`, `login`).

```mermaid
graph TD
    UI[Flutter UI Layer] --> MobX[MobX Controllers / Stores]
    MobX --> Repositories[Repository Interface Layer]
    Repositories --> Drift[Drift SQLite Local Database]
    Repositories --> Appwrite[Appwrite BaaS Remote API]
    Drift <--> Appwrite[Background Sync Engine]
```

### Principais Tecnologias e Bibliotecas

- **Framework**: [Flutter](https://flutter.dev) (gerenciado via **FVM** - Flutter Version Manager).
- **Gerenciamento de Estado**: [MobX](https://pub.dev/packages/mobx) e `flutter_mobx` utilizando reatividade com instanciações manuais (`mobx.Observable`) e mutações seguras via `mobx.runInAction()`.
- **Banco de Dados Local & Cache Offline**: [Drift](https://drift.simonbinder.eu/) (SQLite reativo), permitindo navegação rápida sem dependência imediata de rede.
- **Backend & Backend-as-a-Service (BaaS)**: [Appwrite SDK](https://appwrite.io), gerenciando autenticação de usuários, sessões e persistência remota no banco de dados.
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

#### Divisão por Pesos entre Contatos (`DivisaoTransacaoModel`)
- Suporta a divisão proporcional de uma despesa/receita entre múltiplos contatos.
- Cada divisão possui um `peso` relativo. A parcela de cada participante é calculada via:
  $$\text{Valor do Contato} = \text{Valor Total} \times \left( \frac{\text{Peso do Contato}}{\sum \text{Pesos}} \right)$$
- Se nenhuma divisão for cadastrada, o valor é atribuído 100% ao responsável pela conta.

#### Recorrência e Parcelamentos (`TransacaoRecorrenciaModel`)
- Suporta frequências **diária**, **semanal**, **mensal** e **anual**.
- Cálculo automático das datas de competência de cada parcela com tratamento para anos bissextos e bordas de meses.
- Permite número fixo de parcelas (`totalParcelas`) ou recorrência indeterminada (`fimRecorrencia`).
- Atualizações em série permitem propagação em lote para transações futuras da mesma recorrência.

#### Métricas Mensais e Consolidação
- **`saldoAnterior`**: Soma das transações consolidadas ocorridas estritamente antes do mês selecionado.
- **`receitaMes` / `despesaMes`**: Soma das transações do mês exibido.
- **`saldoAtual`**: Saldo acumulado (Saldo Anterior + Receitas do Mês - Despesas do Mês).
- **Consolidação (`consolidada`)**: Transações consolidadas refletem o saldo real efetivado; transações não consolidadas alimentam as projeções financeiras.

---

### 🎯 2. Módulo de Tarefas e Hábitos

Acompanhamento do desenvolvimento pessoal através da criação e monitoramento de hábitos e execução de tarefas.

#### Janelas de Reinício e Frequência de Hábitos
- Configuração de ciclos de reinício por **dias**, **semanas**, **meses** ou **anos**.
- Extensão `toTarefaHabitoQtdModelList` calcula automaticamente o total de execuções dentro da janela ativa.
- **Métrica de Progresso**:
  $$\text{vezesPraticado} = \text{Quantidade de Históricos na Janela} \times \text{Valor Multiplicador}$$
- **Meta Atingida**: Hábito considerado concluído no ciclo quando $\text{vezesPraticado} \ge \text{metaVezes}$.

#### Matriz de Calendário, Histórico e Cache Reativo
- Matriz dinâmica de dias (35 ou 42 células) gerada pelo `CalendarioController` exibindo preenchimento dos dias vizinhos.
- Histórico imutável de execuções (`HistoricoItemModel`) registrado no banco local e sincronizado remotamente.
- **Cache-First & Sincronização Incremental (Delta Sync)**: Renderização instantânea dos hábitos e tarefas diretamente do Drift SQLite, com sincronização em segundo plano filtrando registros alterados via `$updatedAt` e timestamps salvos em `AppSettings`.

---

### 🔑 3. Módulo de Autenticação

- Gerenciamento de sessão via `LoginController` integrado ao Appwrite `Account`.
- Persistência e restauração offline do perfil do usuário em `Drift SQLite` (`AppSettings`) para acesso sem conexão à internet.
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

---

## 🧪 Suíte de Testes Automatizados

O projeto conta com uma suíte de testes unitários e de integração validando todas as regras de negócio:

### Executando os Testes

Para rodar todos os testes automatizados da aplicação:

```bash
fvm flutter test
```

### Estrutura dos Arquivos de Teste (`test/`)

- `test/business_logic/financas_business_test.dart`: Testes de cálculo de divisão por pesos, geração de datas recorrentes, transferências e resumos de saldo mensal.
- `test/business_logic/tarefas_habitos_business_test.dart`: Testes de janelas de reinício de hábitos, progresso de metas e matriz de calendário.
- `test/business_logic/login_business_test.dart`: Testes de validação de formulários e estados da sessão de autenticação.
- `test/business_logic/drift_cache_sync_test.dart`: Teste automatizado que varre a codebase para garantir que nenhuma consulta viole a regra do `Query.select()` do Appwrite, e teste de preservação do cache local Drift.
- `test/drift_financas_repository_test.dart`: Testes de integração das operações no banco SQLite local.
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
