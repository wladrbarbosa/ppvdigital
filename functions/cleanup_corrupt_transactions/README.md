# Appwrite Function: Limpeza de Transações Indevidas (Cleanup Corrupt Transactions)

Esta Cloud Function foi desenvolvida para realizar a limpeza em massa e reconciliação segura de transações criadas indevidamente (por exemplo, transações com descrição vazia geradas por execuções anômalas), exclusão de divisões órfãs e recálculo dos checkpoints de `fimRecorrencia` na tabela `transacao_recorrencia`.

Por ser uma Cloud Function executada diretamente no ambiente seguro do Appwrite, **nenhuma chave de API ou segredo precisa ser publicado ou comitado no repositório GitHub**.

---

## Recursos e Funcionamento

1. **Varredura Segura com Decodificação Completa**:
   - Consulta transações candidatas a exclusão (`descricao == ""` por padrão, ou por `recurrenceId`).
   - Paginação via cursores nativos sem limite de quantidade.
2. **Exclusão em Lote Concorrente**:
   - Exclui os documentos de transações em paralelo via pool de workers configurável (padrão 20, máx 50).
   - Não depende do endpoint `deleteDocuments` (que falha no Appwrite em tabelas com relacionamentos).
3. **Limpeza de Divisões Órfãs**:
   - Localiza e remove registros em `divisao_transacoes` residuais que tenham ficado órfãos ou com `peso: 0`.
4. **Reconciliação dos Checkpoints de Recorrência**:
   - Para cada regra de recorrência indeterminada (`totalParcelas == null`), busca a última transação legítima com descrição válida e restaura o campo `fimRecorrencia` com a data real correta.

---

## Parâmetros de Execução (JSON Payload Opcional)

Ao invocar ou testar a função no console do Appwrite (ou via API/SDK), você pode passar um corpo JSON:

```json
{
  "dryRun": false,
  "emptyDescOnly": true,
  "recurrenceId": "",
  "concurrency": 20,
  "reconcile": true
}
```

- **`dryRun`** (*boolean*, padrão `false`): se `true`, simula a busca e contabiliza os registros sem deletar nada.
- **`emptyDescOnly`** (*boolean*, padrão `true`): foca nas transações com descrição vazia.
- **`recurrenceId`** (*string*, opcional): foca apenas nas transações de uma regra específica.
- **`concurrency`** (*int*, padrão `20`): número de conexões simultâneas de exclusão.
- **`reconcile`** (*boolean*, padrão `true`): recalcula os checkpoints em `transacao_recorrencia`.

### Resposta Retornada

```json
{
  "success": true,
  "dryRun": false,
  "deletedTransactions": 0,
  "failedTransactions": 0,
  "deletedDivisions": 0,
  "reconciledCheckpoints": 75
}
```

---

## Configuração no Console do Appwrite

### Variáveis de Ambiente
Configurar nas variáveis da função (ou herdar do projeto):
1. `APPWRITE_API_KEY`: API Key com permissões de leitura/escrita no banco (coleções `transacoes`, `transacao_recorrencia` e `divisao_transacoes`).
2. `APPWRITE_ENDPOINT`: Endpoint da API do Appwrite (ex: `https://appwrite.wladapps.com/v1`).
3. `APPWRITE_FUNCTION_PROJECT_ID`: ID do projeto (injetado automaticamente pelo Appwrite).

### Permissões e Escopos (Scopes)
Marcar na função os escopos:
- `databases.read`, `databases.write`
- `documents.read`, `documents.write`

---

## Deploy

### Opção 1: Upload Manual (TAR.GZ)
1. Gere o pacote:
   ```bash
   tar -czvf functions/cleanup_corrupt_transactions.tar.gz -C functions/cleanup_corrupt_transactions main.go go.mod go.sum
   ```
2. No console do Appwrite, acesse a função -> **Deployments** -> **Create deployment**.
3. Selecione o arquivo `cleanup_corrupt_transactions.tar.gz`, defina `main.go` como entrypoint e ative.

### Opção 2: Integração com Git (VCS)
Ao comitar e enviar para a branch monitorada pelo Appwrite, a função será compilada e atualizada automaticamente sem exposição de segredos.
