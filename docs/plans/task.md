| Task | Status | Description |
|---|---|---|
| 1. Implementar suporte a expansão e redução de parcelas em `FinancasController.updateTransacao` | COMPLETED | Suporte a criação de parcelas faltantes e exclusão de parcelas excedentes em `current_and_future` e `all` |
| 2. Aprimorar `CriarEditarTransacaoPage` | COMPLETED | Limpeza de sufixo `(Parcela X/Y)`, preenchimento de `Parcela Atual` e label dinâmico |
| 3. Implementar testes unitários para expansão, redução e desassociação de parcelas | COMPLETED | Testes cobrindo criação de novas parcelas, redução, e o cenário relatado pelo usuário |
| 4. Verificação Global e Análise Estática | COMPLETED | `fvm flutter test` (148 passaram) e `fvm flutter analyze` sem erros |
