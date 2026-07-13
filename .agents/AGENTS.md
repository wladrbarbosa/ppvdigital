# PPVDigital Project Rules and Guidelines

Welcome agent! This file contains project-specific guidelines, technical rules, and gotchas discovered during the development of PPVDigital. Follow these rules to ensure high performance, correct behavior, and consistency.

---

## 1. Appwrite API & Relationship Queries
* **Do NOT use `*` wildcard with relationship wildcards:**
  In Appwrite databases API, combining the root wildcard `'*'` with relationship wildcards (e.g., `'conta.*'`) inside `Query.select()` is not supported. Doing so will result in root attributes (like `descricao` or `valor`) returning `null` or empty.
  * **Rule:** Always explicitly list all required root attributes in the projection array:
    ```dart
    Query.select([
      'descricao',
      'valor',
      'tipo',
      'dataCompetencia',
      'consolidada',
      'conta.*',
      'contaDestino.*',
      // ...
    ])
    ```

---

## 2. Drift SQLite Cache & Offline Sync
* **Maintain Cache Integrity:**
  When syncing remote data with the local database, ensure that lightweight or partial query results do not overwrite complete database rows already stored in Drift.
  * **Rule:** If you fetch partial models (e.g. without descriptions for balance calculations), do NOT insert them into SQLite if they would overwrite full existing rows. Keep them in memory or fetch full records.

---

## 3. MobX State Management
* **Manual Observables:**
  This project uses manual MobX observable instantiations rather than code-generated (`_$`) stores.
  * **Rule:** When creating new observable properties in controllers, declare them manually using the `mobx` prefix and instantiate them directly:
    ```dart
    final mobx.Observable<bool> _isSyncing = mobx.Observable<bool>(false, name: 'isSyncing');
    bool get isSyncing => _isSyncing.value;
    ```
  * **Rule:** Always wrap any state mutations (writing to `.value` or modifying `ObservableList` items) inside `mobx.runInAction(() { ... })`.

---

## 4. UI/UX & Offline State Handling
* **Non-Blocking Background Sync:**
  Background remote sync operations must not block the user interface.
  * **Rule:** Use a subtle `LinearProgressIndicator` (e.g. at the top of a list or below navigation bars) to indicate that sync is active in the background. Do not use fullscreen loading overlays.
* **Avoid Empty State Flickering:**
  When navigating between views/months, cached data is loaded first, then updated from remote.
  * **Rule:** If the local cache is empty, do NOT display an empty state warning (e.g., "Nenhuma transação encontrada") while a sync is actively fetching remote data. Show a `CircularProgressIndicator` instead until the sync completes.

---

## 5. Assets & Date/Timezone Handling (Flutter Web Offline)
* **Timezone Asset Fallbacks:**
  Timezone databases (e.g. `packages/timezone/data/latest_all.tzf`) may fail to load when the app is offline or running under strict cross-origin restrictions in browsers.
  * **Rule:** Wrap all date and calendar initialization code in robust try-catch blocks to prevent critical UI breaks when timezone files are inaccessible.

---

## 6. Flutter Version Management (FVM)
* **Always prefix commands with `fvm`:**
  This project pins its Flutter SDK version using FVM to guarantee environment consistency and reproducible builds.
  * **Rule:** Never run global `flutter` commands. Always use `fvm flutter <command>` (e.g., `fvm flutter analyze`, `fvm flutter pub get`, `fvm flutter run`).
