# Architecture, Performance & Dart 3 Modernization Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Implement critical architecture decoupling, SQLite indexes and lightweight delta sync optimization, MobX getter optimization, Dart 3 modern enums and switch expressions, and comprehensive unit tests.

**Architecture:** Layered approach with pure Domain services for financial recurrence, optimized Drift SQLite with indexes, lightweight Appwrite ID projection queries for deletion reconciliation, and unmodifiable MobX observable getters.

**Tech Stack:** Flutter 3.47, Dart 3.13, Drift SQLite, MobX, Appwrite SDK, flutter_test.

---

### Task 1: Drift SQLite Índices & Schema Upgrade (v6)
**Files:**
- Modify: `lib/models/local/app_database.dart`
- Generate: `lib/models/local/app_database.g.dart`
- Test: `test/drift_financas_repository_test.dart`

### Task 2: Modelo TransacaoModel & Enums Tipados (Dart 3)
**Files:**
- Create: `lib/models/enums.dart`
- Modify: `lib/models/transacao_model.dart`
- Test: `test/unit/transacao_model_test.dart`

### Task 3: Sincronização Otimizada no Delta Sync (Appwrite + Drift)
**Files:**
- Modify: `lib/repositories/financas_repository.dart`
- Modify: `lib/repositories/appwrite_financas_repository.dart`
- Modify: `lib/repositories/drift_financas_repository.dart`
- Modify: `lib/repositories/tarefa_habito_repository.dart`
- Modify: `lib/repositories/appwrite_tarefa_habito_repository.dart`
- Modify: `lib/repositories/drift_tarefa_habito_repository.dart`

### Task 4: Otimização de Memória e Reatividade MobX / Flutter
**Files:**
- Modify: `lib/app/capacitacao/financas/financas_controller.dart`
- Modify: `lib/root_app_widget.dart`

### Task 5: Camada de Domínio: Desacoplamento do Cálculo de Recorrência
**Files:**
- Create: `lib/app/capacitacao/financas/services/recorrencia_service.dart`
- Modify: `lib/app/capacitacao/financas/financas_controller.dart`
- Test: `test/unit/recorrencia_service_test.dart`

### Task 6: Testes Unitários de Alta Criticidade e Validação
**Files:**
- Create: `test/unit/util_test.dart`
- Create: `test/unit/financas_controller_test.dart`
