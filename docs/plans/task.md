| Task | Status | Description |
|---|---|---|
| Task 1: Investigação e Diagnóstico | COMPLETED | Identificada causa raiz do desaparecimento do FAB, identificada causa do prompt Google no boot, e mapeados os lints do analyzer |
| Task 2: Resolução das Questões do `fvm flutter analyze` | COMPLETED | Corrigidos todos os 16 lints do analyzer com 0 avisos/erros |
| Task 3: Correção do Floating Action Button (FAB) | COMPLETED | Restauração de ExpandableFab.location no Scaffold de Hábitos/Tarefas e Finanças e teste de widget |
| Task 4: Diagnóstico e Ajuste do Prompt de Conexão com o Google | COMPLETED | Removida chamada automática de signInSilently() do startup em BackupController.loadSettings(), garantindo conexão sob demanda |
| Task 5: Verificação Completa e Testes Automatizados | COMPLETED | Executados `fvm flutter analyze` e `fvm flutter test` |
| Task 6: Migração para Bibliotecas Modulares de UI e flutter_expandable_fab 3.0.0 | COMPLETED | Adicionado `material_ui: ^1.2.0`, atualizado `flutter_expandable_fab: 3.0.0`, migrados 62 arquivos para `package:material_ui/material_ui.dart`, adaptada tipografia do GoogleFonts e validados 290/290 testes (100% de sucesso) |
| Task 7: Restabelecimento do Tema no Syncfusion Calendar (SfCalendar) | COMPLETED | Implementado `ThemeBridge` conectando `material_ui.ThemeData` com `flutter_material.Theme` e `SfCalendarTheme`, preservando o Design System Pastel & Leveza sem remover `material_ui` e sem qualquer downgrade (294/294 testes aprovados) |
