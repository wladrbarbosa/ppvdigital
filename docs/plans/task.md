| Task | Status | Description |
|---|---|---|
| 1. Adicionar coluna dataCriacao no Appwrite e suporte a parsing no modelo/extensões | COMPLETED | Coluna criada no Appwrite, parsing implementado e testado com 100% de sucesso |
| 2. Implementar método updateHistoricoItemDate na interface e repositórios | COMPLETED | updateHistoricoItemDate implementado com otimistic update, fila offline e testes passando |
| 3. Implementar método updateHistoricoDate em HistoricoController | COMPLETED | updateHistoricoDate implementado com atualização otimista na lista e testes passando |
| 4. Habilitar Drag & Drop e Modal de Edição de Data/Hora na CalendarioPage | COMPLETED | allowDragAndDrop + onDragEnd e modal com date & time picker nos tokens do Design System implementados e testados |
| 5. Verificação Global e Documentação | COMPLETED | fvm flutter analyze (zero erros), fvm flutter test (164/164 passando) e README.md atualizado |
| 6. Correção do Drag & Drop no Calendário (preservação de relações em Realtime e horário em MonthView) | COMPLETED | Prevenir sobrescrita de tarefaHabitoId/usuario em eventos Realtime e preservar hora/minuto em MonthView |
