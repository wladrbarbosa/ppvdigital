# Appwrite Function: Generate Infinite Recurring Transactions

Esta função automatiza a criação de novas transações e respectivas divisões para todas as transações com **recorrência indeterminada (infinita)** cadastradas no banco de dados.

## Como funciona
1. A função roda periodicamente (agendada via Cron, recomendada mensalmente ou diária).
2. Ela busca todas as regras de recorrência indeterminadas da tabela `transacao_recorrencia` (registros que possuem `totalParcelas` nulo).
3. **Filtro de Alta Performance em Memória ($O(1)$)**: Verifica o campo `fimRecorrencia` da regra. Se ele já cobrir o horizonte móvel de 24 ocorrências no futuro (`now + 24 * ciclo`), a regra é ignorada imediatamente sem realizar consultas adicionais no banco.
4. **Buffer Dinâmico com Autocura (24 Ocorrências)**:
   - Suporta qualquer periodicidade (`dia`, `semana`, `quinzenal`, `mês`, `ano`).
   - Se `fimRecorrencia` estiver ausente ou anterior ao horizonte, consulta a última transação existente (`orderDesc("dataCompetencia")`, `limit(1)`).
   - Executa um loop de autocura gerando todas as parcelas faltantes até preencher o buffer de 24 ocorrências (ex.: se houver apenas 20, gera as 4 faltantes).
5. **Clonagem e Divisões**:
   - Clona a transação com a nova data de competência (com `consolidada: false` por padrão).
   - Clona em lote todas as divisões associadas (`divisao_transacoes`).
6. **Checkpoint**:
   - Atualiza `fimRecorrencia` na tabela `transacao_recorrencia` com a data da última parcela gerada, garantindo que execuções subsequentes da Cron pulem a regra sem custos de leitura.

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

### Opção 1: Upload Manual (ZIP)
1. Crie um arquivo ZIP contendo apenas os arquivos `main.go` e `go.mod` (sem pastas adicionais na raiz do zip).
2. No console do Appwrite, vá na função -> aba **Deployments** -> **Create deployment**.
3. Selecione o arquivo ZIP, informe o ponto de entrada como `main.go` (já configurado) e marque a opção para ativar o deployment após a compilação.

### Opção 2: Integração com Git (VCS)
Se a sua função estiver integrada com o repositório Git:
1. Faça o commit e push dos arquivos criados na pasta `functions/process_recurrent_transactions`.
2. O Appwrite iniciará o build automático e implantará a nova versão assim que o código chegar na branch monitorada.
