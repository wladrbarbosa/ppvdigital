import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  Future<void>? _historicoFuture;
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _historicoFuture = Core.historicoController.loadDocuments();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, HistoricoItemModel item) {
    final dateStr = '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year} às ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover registro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deseja realmente remover este registro do histórico?'),
              const SizedBox(height: 16),
              Text(
                'Item: ${item.tarefasEHabitos.nome}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Tipo: ${item.tarefasEHabitos.tipo == 'habito' ? 'Hábito' : 'Tarefa'}'),
              const SizedBox(height: 4),
              Text('Concluído em: $dateStr'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await Core.historicoController
                    .deleteHistoricoItem(item.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro removido com sucesso!'),
                    ),
                  );
                }
              },
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Observer(
            builder: (context) {
              final historyList = Core.historicoController.historicoList;
              final dataSource = _HistoricoDataSource(historyList);

              return LayoutBuilder(
                builder: (context, constraints) {


                  final calendarWidget = SfCalendar(
                    controller: _calendarController,
                    dataSource: dataSource,
                    showDatePickerButton: true,
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      minimumAppointmentDuration: Duration(minutes: 30),
                      timeFormat: 'HH:mm',
                    ),
                    allowedViews: const [
                      CalendarView.day,
                      CalendarView.week,
                      CalendarView.month,
                      CalendarView.timelineWeek,
                      CalendarView.schedule,
                    ],
                    appointmentTimeTextFormat: 'HH:mm',
                    onTap: (CalendarTapDetails details) {
                      if (details.appointments != null &&
                          details.appointments!.isNotEmpty) {
                        final Appointment appt =
                            details.appointments!.first as Appointment;
                        final itemId = appt.id as String?;
                        if (itemId != null) {
                          final item = historyList.firstWhere(
                            (el) => el.id == itemId,
                          );
                          _showDeleteDialog(context, item);
                        }
                      }
                    },
                  );

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _calendarController.displayDate =
                                      DateTime.now();
                                });
                              },
                              icon: const Icon(Icons.today),
                              label: const Text('Hoje'),
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: calendarWidget),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoricoDataSource extends CalendarDataSource {
  _HistoricoDataSource(List<HistoricoItemModel> source) {
    appointments = source.map((item) {
      final category = item.tarefasEHabitos.tarefasHabitosQtd.isNotEmpty
          ? item
                .tarefasEHabitos
                .tarefasHabitosQtd
                .first
                .categoriasTarefasHabitos
          : null;
      return Appointment(
        id: item.id,
        startTime: item.createdAt.toLocal(),
        endTime: item.createdAt.toLocal().add(const Duration(minutes: 30)),
        subject: item.tarefasEHabitos.nome,
        color: category?.cor ?? Colors.blue,
        notes: item.id,
      );
    }).toList();
  }
}
