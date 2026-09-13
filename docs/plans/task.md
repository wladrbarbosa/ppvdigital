| Task | Status | Description |
|---|---|---|
| 1. Dependências e Modelo de Dados (`BackupPayloadModel`) | COMPLETED | Adicionados googleapis e google_sign_in em pubspec.yaml, criado BackupPayloadModel com integridade SHA-256 e suíte de testes com 100% de cobertura (passado e futuro) |
| 2. Serviço de Extração e Backup (`BackupService`) | COMPLETED | Implementado BackupService com extração paginada das 10 tabelas, cobertura temporal irrestrita (passado, presente e futuro) e 100% de cobertura de testes |
| 3. Serviço de Restauração Segura (`RestoreService`) | COMPLETED | Implementado RestoreService com integridade referencial em 4 etapas, validação SHA-256, upsert/limpeza reversa e 100% de cobertura de testes |
| 4. Serviço Google Drive (`GoogleDriveBackupService`) | IN_PROGRESS | Implementar autenticação OAuth2 com escopo `drive.file`, upload diário, rotação de 30 dias, listagem/download e testes unitários |
| 5. Gerenciamento de Estado (`BackupController` & `Core`) | PENDING | Implementar controller MobX com observables manuais, verificação diária automática de 24h, registro no GetIt e testes de controller |
| 6. Interface de Usuário no `ConfiguracoesModalWidget` | PENDING | Criar seção de Backup/Restauração no modal de configurações e diálogo interativo de progresso/resumo com Design System Pastel |
| 7. Verificação Completa e Relatório (`flutter test` / `analyze`) | PENDING | Executar suíte completa de testes e análise estática, garantindo máxima cobertura sem regressões |
