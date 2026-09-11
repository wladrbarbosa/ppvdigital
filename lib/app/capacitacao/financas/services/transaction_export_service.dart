import 'package:intl/intl.dart';
import 'package:ppvdigital/app/capacitacao/financas/services/file_saver.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/util.dart';

class TransactionExportService {
  /// Gera um texto amigável formatado para WhatsApp.
  static String formatWhatsApp({
    required List<TransacaoModel> transactions,
    required bool groupByDateWithBalance,
    Map<String, double>? saldosDiarios,
    required DateTime currentMonth,
    String? filterSummary,
  }) {
    final buffer = StringBuffer();
    final monthName = DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(currentMonth);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    buffer.writeln('📊 *Relatório de Transações - $capitalizedMonth*');
    if (filterSummary != null && filterSummary.trim().isNotEmpty) {
      buffer.writeln('Filtros: ${filterSummary.trim()}');
    }
    buffer.writeln('────────────────────────────');

    if (transactions.isEmpty) {
      buffer.writeln('Nenhuma transação encontrada para o período/filtros selecionados.');
      return buffer.toString().trim();
    }

    double totalReceitas = 0.0;
    double totalDespesas = 0.0;

    for (final t in transactions) {
      if (t.tipo == 'receita') {
        totalReceitas += t.valor;
      } else if (t.tipo == 'despesa') {
        totalDespesas += t.valor;
      }
    }
    final double saldoLiquido = totalReceitas - totalDespesas;

    String formatCurrency(num val) {
      return val.toCurrency().replaceAll('\u00A0', ' ');
    }

    if (groupByDateWithBalance) {
      // Agrupar por data (yyyy-MM-dd)
      final Map<String, List<TransacaoModel>> groups = {};
      for (final t in transactions) {
        final dateKey = DateFormat('yyyy-MM-dd').format(t.dataCompetencia);
        groups.putIfAbsent(dateKey, () => []).add(t);
      }

      final sortedKeys = groups.keys.toList()..sort((a, b) => a.compareTo(b));

      for (var i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        final dayTrans = groups[key]!;
        final firstDate = dayTrans.first.dataCompetencia;
        final dateFormatted = DateFormat('dd/MM/yyyy').format(firstDate);
        final diaSemanaRaw = DateFormat('EEEE', 'pt_BR').format(firstDate);
        final diaSemana = diaSemanaRaw[0].toUpperCase() + diaSemanaRaw.substring(1);

        buffer.writeln('📅 *$dateFormatted ($diaSemana)*');

        for (final t in dayTrans) {
          final String emoji = t.tipo == 'receita'
              ? '🟢'
              : (t.tipo == 'transferencia' ? '🔵' : '🔴');

          String details = '';
          if (t.tipo == 'transferencia') {
            final origem = t.conta?.name ?? '';
            final destino = t.contaDestino?.name ?? '';
            if (origem.isNotEmpty || destino.isNotEmpty) {
              details = ' ($origem ➔ $destino)';
            }
          } else {
            final parts = <String>[];
            if (t.categoria?.name != null && t.categoria!.name.isNotEmpty) {
              parts.add(t.categoria!.name);
            }
            if (t.conta?.name != null && t.conta!.name.isNotEmpty) {
              parts.add(t.conta!.name);
            }
            if (parts.isNotEmpty) {
              details = ' (${parts.join(' - ')})';
            }
          }

          buffer.writeln('• $emoji ${t.descricao}: ${formatCurrency(t.valor)}$details');
        }

        if (saldosDiarios != null && saldosDiarios.containsKey(key)) {
          final double saldoDia = saldosDiarios[key]!;
          buffer.writeln('💰 *Saldo acumulado do dia:* ${formatCurrency(saldoDia)}');
        }

        if (i < sortedKeys.length - 1) {
          buffer.writeln();
        }
      }

      buffer.writeln();
      buffer.writeln('────────────────────────────');
      buffer.writeln('📈 *Resumo do Período:*');
      buffer.writeln('• Total Receitas: ${formatCurrency(totalReceitas)}');
      buffer.writeln('• Total Despesas: ${formatCurrency(totalDespesas)}');
      buffer.writeln('• *Saldo Líquido:* ${formatCurrency(saldoLiquido)}');
    } else {
      // Modo linear
      final sortedTrans = List<TransacaoModel>.from(transactions)
        ..sort((a, b) => a.dataCompetencia.compareTo(b.dataCompetencia));

      for (final t in sortedTrans) {
        final dateFormatted = DateFormat('dd/MM').format(t.dataCompetencia);
        final sign = t.tipo == 'receita' ? '+' : (t.tipo == 'despesa' ? '-' : '');
        final detail = t.categoria?.name ?? (t.conta?.name ?? '');
        final detailStr = detail.isNotEmpty ? ' ($detail)' : '';

        buffer.writeln('• $dateFormatted - ${t.descricao}: $sign${formatCurrency(t.valor)}$detailStr');
      }

      buffer.writeln('────────────────────────────');
      buffer.writeln('📈 *Total Geral:*');
      buffer.writeln('• Receitas: ${formatCurrency(totalReceitas)}');
      buffer.writeln('• Despesas: ${formatCurrency(totalDespesas)}');
      buffer.writeln('• *Saldo:* ${formatCurrency(saldoLiquido)} (${transactions.length} transações)');
    }

    return buffer.toString().trim();
  }

  /// Gera uma representação CSV com delimitador ';' e BOM UTF-8 (\uFEFF).
  static String formatCsv({
    required List<TransacaoModel> transactions,
    required bool groupByDateWithBalance,
    Map<String, double>? saldosDiarios,
    required DateTime currentMonth,
  }) {
    final buffer = StringBuffer('\uFEFF');

    String escapeCsv(String val) {
      if (val.contains(';') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
        return '"${val.replaceAll('"', '""')}"';
      }
      return val;
    }

    if (groupByDateWithBalance) {
      buffer.writeln('Data;Descrição;Categoria;Conta;Tipo;Status;Valor;Saldo Acumulado');
    } else {
      buffer.writeln('Data;Descrição;Categoria;Conta;Tipo;Status;Valor');
    }

    if (transactions.isEmpty) {
      final suffix = groupByDateWithBalance ? ';' : '';
      buffer.writeln('Nenhuma transação encontrada;;;;;;$suffix');
      return buffer.toString();
    }

    final sortedTrans = List<TransacaoModel>.from(transactions)
      ..sort((a, b) => a.dataCompetencia.compareTo(b.dataCompetencia));

    double totalReceitas = 0.0;
    double totalDespesas = 0.0;

    for (final t in sortedTrans) {
      if (t.tipo == 'receita') {
        totalReceitas += t.valor;
      } else if (t.tipo == 'despesa') {
        totalDespesas += t.valor;
      }

      final dateStr = DateFormat('dd/MM/yyyy').format(t.dataCompetencia);
      final desc = escapeCsv(t.descricao);
      final cat = escapeCsv(t.categoria?.name ?? '');

      String contaStr = t.conta?.name ?? '';
      if (t.tipo == 'transferencia' && t.contaDestino != null) {
        contaStr = '${t.conta?.name ?? ''} -> ${t.contaDestino?.name ?? ''}';
      }
      final conta = escapeCsv(contaStr);

      final tipo = t.tipo == 'receita'
          ? 'Receita'
          : (t.tipo == 'transferencia' ? 'Transferência' : 'Despesa');
      final status = t.consolidada ? 'Consolidada' : 'Pendente';

      final valorStr = t.tipo == 'despesa'
          ? '-${t.valor.toPtBr()}'
          : t.valor.toPtBr();

      if (groupByDateWithBalance) {
        final dateKey = DateFormat('yyyy-MM-dd').format(t.dataCompetencia);
        final saldoAcumulado = saldosDiarios != null && saldosDiarios.containsKey(dateKey)
            ? saldosDiarios[dateKey]!.toPtBr()
            : '';
        buffer.writeln('$dateStr;$desc;$cat;$conta;$tipo;$status;$valorStr;$saldoAcumulado');
      } else {
        buffer.writeln('$dateStr;$desc;$cat;$conta;$tipo;$status;$valorStr');
      }
    }

    final saldoLiquido = totalReceitas - totalDespesas;
    final suffix = groupByDateWithBalance ? ';' : '';

    buffer.writeln('TOTAL RECEITAS;;;;;;${totalReceitas.toPtBr()}$suffix');
    buffer.writeln('TOTAL DESPESAS;;;;;;-${totalDespesas.toPtBr()}$suffix');
    buffer.writeln('SALDO LÍQUIDO;;;;;;${saldoLiquido.toPtBr()}$suffix');

    return buffer.toString();
  }

  /// Dispara o download ou salvamento do arquivo CSV na plataforma atual.
  static Future<String?> downloadCsvFile({
    required String csvContent,
    required String fileName,
  }) async {
    return saveCsvFile(csvContent, fileName);
  }
}

