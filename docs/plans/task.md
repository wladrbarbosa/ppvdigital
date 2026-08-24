| Task | Status | Description |
|---|---|---|
| 1. Drift SQLite Índices & Schema Upgrade (v6) | COMPLETED | Adicionar índices SQL em `Transacaos`, `HistoricoTarefasHabitos`, `TarefaHabitos`, `Contas` e atualizar schema para v6 |
| 2. Enums Tipados (Dart 3) e Correção de Igualdade em TransacaoModel | COMPLETED | Criar `TipoTransacao`, `TipoItem`, `TipoHabito`, `TipoRecorrencia` e corrigir `operator ==` com `divisoes` |
| 3. Otimização do Delta Sync (Projeção Leve de IDs no Appwrite & Drift) | COMPLETED | Projetar apenas `['$id']` nas consultas de reconciliação de exclusão sem carregar payloads completos |
| 4. Otimização de Memória nos Getters MobX e Streams | COMPLETED | Eliminar alocações repetidas de `.toList()` e queries redundantes `await stream.first` no `FinancasController` |
| 5. Desacoplamento da Camada de Domínio com RecorrenciaService | COMPLETED | Extrair lógica pura de cálculo de parcelas e datas com switch expressions do Dart 3 |
| 6. Expansão da Suíte de Testes Automatizados | COMPLETED | Implementar testes para `util.dart`, `RecorrenciaService`, `TransacaoModel` e `FinancasController`, validando cobertura com `fvm flutter test` |
