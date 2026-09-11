# Design Document: Exportação de Transações Filtradas (WhatsApp & CSV)

Data: 2026-09-11  
Status: Aprovado

## 1. Visão Geral e Contexto

Na tela de finanças (`FinancasLayout`), o usuário gerencia suas transações mensais com filtros avançados de busca textual, contas bancárias, categorias, tipos (receita, despesa, transferência), contatos e status de consolidação.
Este documento especifica a adição de uma funcionalidade de exportação diretamente na barra de troca de mês (`SeletorMesWidget`), permitindo exportar a visualização filtrada atual em dois formatos principais:
1. **Texto Amigável para WhatsApp** (estruturado com emojis e markdown do WhatsApp).
2. **CSV** (delimitado por `;`, compatível com Excel e Google Sheets em português).

Ambos os formatos suportam duas estruturas de agrupamento:
- **Agrupado por data com saldo acumulado:** exibe datas, transações do respectivo dia e o saldo acumulado diário apurado até aquele ponto.
- **Somente transações com total:** lista direta de transações com resumo de total de receitas, despesas e saldo final consolidado.

O usuário pode copiar diretamente para a área de transferência com um clique e, quando em CSV, realizar o download do arquivo `.csv`.

---

## 2. Requisitos e Regras de Negócio

1. **Escopo dos Dados:**
   - A exportação deve considerar estritamente a lista `filteredTransList` (com todos os filtros ativos e busca textual aplicados).
   - Deve respeitar os saldos diários acumulados calculados em `saldosDiarios` e o contexto do mês visualizado.

2. **Formato WhatsApp:**
   - Utilizar formatação do WhatsApp (`*negrito*`, `_itálico_`, marcadores `•`).
   - Identificação visual amigável de tipos de transação:
     - 🟢 Receitas
     - 🔴 Despesas
     - 🔵 Transferências
   - Quando agrupado por data, exibir cabeçalho de data (`📅 dd/MM/yyyy (Dia da Semana)`), transações com valores e categoria/conta, e linha de `💰 Saldo acumulado do dia: R$ X,XX`.
   - Ao final, resumo do período com total de receitas, total de despesas e saldo líquido.

3. **Formato CSV:**
   - Padrão brasileiro/europeu com separador de campos ponto e vírgula (`;`), permitindo que o Excel abra os números decimais com vírgula corretamente.
   - Prefixado com UTF-8 Byte Order Mark (`\uFEFF`) para preservar acentuação (pt-BR) nativamente no Excel sem exigir assistente de importação.
   - Colunas: `Data;Descrição;Categoria;Conta;Tipo;Status;Valor` (e `Saldo Acumulado` quando no modo agrupado).
   - Linhas finais de rodapé com totalizadores gerais.

4. **UI & Experiência do Usuário (Design System):**
   - Botão de exportação no `SeletorMesWidget` no lado direito, alinhado com o botão de próximo mês.
   - Diálogo modal responsivo `ExportarTransacoesDialog`:
     - Seletor de formato (WhatsApp vs CSV) via chips/segmented buttons com design pastel (`AppColors`, `AppRadius.roundedMd`).
     - Seletor de estrutura (Por data com saldo acumulado vs Somente transações com total).
     - Caixa de pré-visualização ao vivo com scroll para conferência instantânea.
     - Botão primário "Copiar para Área de Transferência" (feedback via `SnackBar`).
     - Botão secundário "Baixar Arquivo .csv" habilitado quando CSV selecionado.

5. **Compatibilidade Multiplataforma (Web e Mobile/Desktop):**
   - Na Web: download disparado via `Blob` e âncora de download invisível.
   - No Mobile/Desktop: salvar em pasta de documentos/cache via `path_provider` e exibir notificação de sucesso com o caminho do arquivo.

---

## 3. Arquitetura e Estrutura de Código

### 3.1. `TransactionExportService`
Arquivo: `lib/app/capacitacao/financas/services/transaction_export_service.dart`

Responsável puro pela lógica de formatação e download:
```dart
class TransactionExportService {
  static String formatWhatsApp({
    required List<TransacaoModel> transactions,
    required bool groupByDateWithBalance,
    Map<String, double>? saldosDiarios,
    required DateTime currentMonth,
    String? filterDescription,
  });

  static String formatCsv({
    required List<TransacaoModel> transactions,
    required bool groupByDateWithBalance,
    Map<String, double>? saldosDiarios,
    required DateTime currentMonth,
  });

  static Future<void> downloadCsvFile({
    required String csvContent,
    required String fileName,
  });
}
```

### 3.2. `ExportarTransacoesDialog`
Arquivo: `lib/app/capacitacao/financas/widgets/exportar_transacoes_dialog.dart`

Widget com estado próprio que gerencia a seleção de opções pelo usuário, invoca `TransactionExportService` para atualizar a pré-visualização e dispara as ações de cópia e download.

### 3.3. `SeletorMesWidget`
Arquivo: `lib/app/capacitacao/financas/widgets/seletor_mes_widget.dart`

Adiciona o parâmetro opcional `VoidCallback? onExportPressed` e renderiza um `IconButton` elegante com `Icons.share_outlined` na barra superior de seleção de meses.

### 3.4. `FinancasLayout`
Arquivo: `lib/app/capacitacao/financas/financas_layout.dart`

Conecta o callback `onExportPressed` do `SeletorMesWidget` à abertura de `ExportarTransacoesDialog`, passando:
- `filteredTransList`
- `saldosDiarios`
- `_appliedMonth`
- Resumo textual dos filtros aplicados (ex.: contas, categorias, tipos ou query)

---

## 4. Estratégia de Testes (~100% de Cobertura)

1. **Testes Unitários:** `test/unit/transaction_export_service_test.dart`
   - Teste de `formatWhatsApp` com modo data + saldo acumulado.
   - Teste de `formatWhatsApp` com modo linear + total geral.
   - Teste de formatação com listas vazias e transações de valores negativos/positivos.
   - Teste de `formatCsv` verificando BOM `\uFEFF`, delimitadores `;`, cabeçalhos e totais.
   - Teste de escaping de aspas duplas e quebras de linha em descrições no CSV.

2. **Testes de Widget:** `test/widget/exportar_transacoes_dialog_test.dart`
   - Teste de renderização do diálogo e suas opções.
   - Teste de alternância entre WhatsApp e CSV e atualização do texto de pré-visualização.
   - Teste de alternância entre agrupado por data e linear.
   - Teste do botão de cópia chamando `Clipboard`.
   - Teste da visibilidade e clique do botão de download CSV.

3. **Testes do SeletorMesWidget:** `test/widget/seletor_mes_widget_test.dart`
   - Teste de renderização do botão de exportação e acionamento do callback `onExportPressed`.
