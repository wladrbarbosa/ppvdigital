| Task | Status | Description |
|---|---|---|
| 1. Isolamento de Transações por Usuário/Contas | COMPLETED | Filtrar estritamente transações locais por `contaIds` em `getTransacoes` e `watchTransacoes`, e validar contas do usuário em `handleRealtimeEvent` |
| 2. Suporte a Hábitos Negativos e Abstinência | COMPLETED | Suporte a hábitos negativos com `metaVezes` como meta de dias sem praticar, contagem de streak/dias de abstinência, preenchimento líquido crescente, cor diferenciada (`deepOrange`), diálogo de confirmação de recaída e ordenação por tipo |
| 3. Campo e Visualização de Tarefas/Hábitos Arquivados | COMPLETED | Adicionar campo `arquivado` ao Drift SQLite (v5), modelo, repositórios, formulário de cadastro e filtro para alternar entre ativos e arquivados |
| 4. Persistência de Hábitos Negativos no Hot Reload & Sync | COMPLETED | Corrigir projeção `Query.select` no Appwrite, merge seguro de metas no SQLite `_upsertTarefaHabito`, parsing de `createdAt` em `TarefaHabitoQtdModel.fromMap` e cálculo histórico de recaídas |
| 5. Testes Automatizados e Análise Estática | COMPLETED | Implementar testes unitários para isolamento de transações, hábitos negativos, cálculo de streak, reconciliação de sync e itens arquivados, validando com `fvm flutter test` e `fvm flutter analyze` (82 testes aprovados) |
