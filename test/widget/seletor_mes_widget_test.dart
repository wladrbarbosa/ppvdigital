import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ppvdigital/app/capacitacao/financas/widgets/seletor_mes_widget.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('SeletorMesWidget exibe mês e navega entre meses', (tester) async {
    DateTime current = DateTime(2026, 9);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SeletorMesWidget(
                selectedMonth: current,
                onMonthChanged: (newMonth) {
                  setState(() {
                    current = newMonth;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('Setembro 2026'), findsOneWidget);

    // Mês anterior
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(current.month, equals(8));

    // Próximo mês
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(current.month, equals(9));
  });

  testWidgets('SeletorMesWidget exibe botão de exportação e dispara callback', (
    tester,
  ) async {
    bool exportClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeletorMesWidget(
            selectedMonth: DateTime(2026, 9),
            onMonthChanged: (_) {},
            onExportPressed: () {
              exportClicked = true;
            },
          ),
        ),
      ),
    );

    final exportFinder = find.byTooltip('Exportar transações');
    expect(exportFinder, findsOneWidget);

    await tester.tap(exportFinder);
    await tester.pumpAndSettle();

    expect(exportClicked, isTrue);
  });
}
