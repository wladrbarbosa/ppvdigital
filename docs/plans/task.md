| Task | Status | Description |
|---|---|---|
| 1. Investigar a causa raiz dos cálculos de previsão do gráfico | COMPLETED | Analisado `dashboard_page.dart`, `dashboard_logic.dart` e histórico de commits |
| 2. Identificar discrepâncias e formular hipótese | COMPLETED | Identificado: fallback de 30min em duração nula, hábitos negativos contabilizados com metaVezes de dias de abstinência, e duplicação por categorias |
| 3. Implementar testes reproduzindo o problema | COMPLETED | Testes adicionados e falhas confirmadas: 300 vs 30 min, 940 vs 40 min, 120 vs 60 min, 65 vs 20 min |
| 4. Corrigir cálculo da previsão e formatação do gráfico | COMPLETED | Corrigido `getPlannedCommitmentTime`, `getExecutedCommitmentTime`, formatação de horas/minutos e dica informativa |
| 5. Verificação e testes globais | COMPLETED | `fvm flutter test` (153 testes passaram) e `fvm flutter analyze` sem erros |
