# Appwrite Function: Generate Infinite Recurring Transactions

Esta função automatiza a criação de novas transações e respectivas divisões para todas as transações com **recorrência indeterminada (infinita)** cadastradas no banco de dados.

## Como funciona
1. A função roda periodicamente (agendada via Cron, recomendada mensalmente ou diária).
2. Ela busca todas as regras de recorrência indeterminadas da tabela `transacao_recorrencia` (registros que possuem `totalParcelas` nulo).
3. **Decodificação Segura (Go SDK v5)**: Utiliza `res.Decode()` para extrair todos os atributos de documentos preservando dados dinâmicos (`descricao`, `valor`, `tipo`, `dataCompetencia`, etc.) sem perda por campos não exportados.
4. **Filtro de Alta Performance em Memória ($O(1)$)**: Verifica o campo `fimRecorrencia` da regra. Se ele já cobrir o horizonte móvel de 24 ocorrências no futuro (`now + 24 * ciclo`), a regra é ignorada imediatamente sem realizar consultas adicionais no banco.
5. **Buffer Dinâmico com Autocura e No-Op Seguro**:
   - Suporta qualquer periodicidade (`dia`, `semana`, `quinzenal`, `mês`, `ano`).
   - Se `fimRecorrencia` estiver ausente ou anterior ao horizonte, consulta a última transação válida existente (`descricao != ""` e `dataCompetencia` válida).
   - **Garante que se não precisar, ela não cria nada**: Se a última transação já alcançar ou ultrapassar o horizonte, nenhum registro é criado e o checkpoint é registrado.
   - **Proteção anti-vazios**: Se a descrição for vazia ou a transação de referência for inválida, a regra é pulada sem gerar dados corrompidos.
   - Se houver lacuna, executa um loop gerando estritamente as parcelas faltantes até preencher o horizonte de 24 ocorrências.
6. **Clonagem e Divisões**:
   - Clona a transação com a nova data de competência (com `consolidada: false` por padrão).
   - Clona em lote todas as divisões associadas (`divisao_transacoes`).
7. **Checkpoint**:
   - Atualiza `fimRecorrencia` na tabela `transacao_recorrencia` com a data da última parcela gerada somente se novas parcelas tiverem sido criadas.

## Função Complementar de Limpeza e Exclusão em Massa

Para operações de auditoria, limpeza em lote de transações indevidas e restauração de checkpoints sem publicação de segredos, utilize a function complementar:
- [`functions/cleanup_corrupt_transactions/`](../cleanup_corrupt_transactions/README.md)


## Configuração no Console do Appwrite

### Agendamento (Schedule)
Configure a expressão Cron no painel da função para executar no dia 1 de cada mês às 3h:
* **Cron Expression**: `0 3 1 * *`

### Variáveis de Ambiente
Você deve configurar as seguintes variáveis de ambiente nas configurações da função no painel do Appwrite:
1. `APPWRITE_API_KEY`: Uma API Key do projeto com permissões para ler e escrever no Database (Documentos das coleções `transacao_recorrencia`, `671f7a6f000cb3ab17b9` (transacoes), e `divisao_transacoes`).
2. `APPWRITE_ENDPOINT`: O endpoint da sua API do Appwrite (se omitido, o padrão é `https://cloud.appwrite.io/v1`).
3. `APPWRITE_FUNCTION_PROJECT_ID`: O ID do seu projeto (já injetado automaticamente pelo Appwrite).

## Deploy

Como a função já está criada no Appwrite (`Generate Infinite Recurring Transactions`, ID `6a414a8100206d23a248`), você pode realizar o deploy da seguinte forma:

### Opção 1: Upload Manual (ZIP/TAR.GZ)
1. Crie um arquivo TAR.GZ com `tar -czvf functions/process_recurrent_transactions.tar.gz -C functions/process_recurrent_transactions main.go go.mod go.sum` contendo apenas os arquivos `main.go`, `go.sum` e `go.mod` (sem pastas adicionais na raiz do zip).
2. No console do Appwrite, vá na função -> aba **Deployments** -> **Create deployment**.
3. Selecione o arquivo TAR.GZ, informe o ponto de entrada como `main.go` (já configurado) e marque a opção para ativar o deployment após a compilação.

### Opção 2: Integração com Git (VCS)
Se a sua função estiver integrada com o repositório Git:
1. Faça o commit e push dos arquivos na pasta `functions/process_recurrent_transactions`.
2. O Appwrite iniciará o build automático e implantará a nova versão assim que o código chegar na branch monitorada.