import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
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
    final dateStr =
        '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year} às ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
    final bool isNegativo =
        item.tarefasEHabitos.tarefasHabitosQtd.any((q) => q.valor < 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover registro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deseja realmente remover este registro do histórico?',
              ),
              const SizedBox(height: 16),
              Text(
                'Item: ${item.tarefasEHabitos.nome}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo: ${item.tarefasEHabitos.tipo == 'habito' ? (isNegativo ? 'Hábito Negativo (Recaída)' : 'Hábito') : 'Tarefa'}',
              ),
              const SizedBox(height: 4),
              Text(
                isNegativo
                    ? 'Recaída em: $dateStr'
                    : 'Concluído em: $dateStr',
              ),
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
      final rawCategory = item.tarefasEHabitos.tarefasHabitosQtd.isNotEmpty
          ? item
                .tarefasEHabitos
                .tarefasHabitosQtd
                .first
                .categoriasTarefasHabitos
          : null;
      final catId = rawCategory?.id;
      final liveCategories = Core.maybeCategoriasController?.categoriasList;
      final liveCategory = (catId != null && catId.isNotEmpty && liveCategories != null)
          ? liveCategories
              .cast<CategoriasTarefasHabitosModel?>()
              .firstWhere((c) => c?.id == catId, orElse: () => null)
          : null;
      final category = liveCategory ?? rawCategory;

      final bool isNegativo = item.tarefasEHabitos.tarefasHabitosQtd
          .any((q) => q.valor < 0);
      final String prefix = isNegativo ? '[Recaída] ' : '';
      final subject = item.tarefasEHabitos.nome.isNotEmpty
          ? '$prefix${item.tarefasEHabitos.nome}'
          : (item.tarefasEHabitos.tipo == 'habito'
              ? (isNegativo ? 'Recaída Registrada' : 'Hábito Praticado')
              : 'Tarefa Concluída');
      final duration = item.tarefasEHabitos.duration ?? 30;

      return Appointment(
        id: item.id,
        startTime: item.createdAt.toLocal(),
        endTime: item.createdAt.toLocal().add(Duration(minutes: duration)),
        subject: subject,
        color: isNegativo
            ? (category?.cor ?? AppColors.pastelError)
            : (category?.cor ??
                (item.tarefasEHabitos.tipo == 'habito'
                    ? AppColors.primaryLight
                    : AppColors.secondaryLight)),
        notes: item.id,
      );
    }).toList();
  }
}
