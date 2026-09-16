import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:material_ui/material_ui.dart';
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

  Future<void> _handleAppointmentDragEnd(
    AppointmentDragEndDetails details,
  ) async {
    final dynamic appointment = details.appointment;
    final DateTime? dropTime = details.droppingTime;
    if (appointment is! Appointment || dropTime == null) return;

    final String? rawId = appointment.id?.toString();
    final String? rawNotes = appointment.notes?.toString();
    final historyList = Core.historicoController.historicoList;
    final item = historyList.cast<HistoricoItemModel?>().firstWhere(
          (el) =>
              (rawId != null && el?.id == rawId) ||
              (rawNotes != null && el?.id == rawNotes),
          orElse: () => null,
        );
    if (item == null) return;
    final String itemId = item.id;

    final DateTime originalLocal = item.createdAt.toLocal();

    // When dropped in Month view (or when dropTime is at midnight 00:00 while the original had a specific hour/minute),
    // preserve the original appointment's hour and minute so it does not jump to midnight.
    DateTime targetDateTime = dropTime;
    final isMonth = _calendarController.view == CalendarView.month;
    if (isMonth ||
        (dropTime.hour == 0 &&
            dropTime.minute == 0 &&
            (originalLocal.hour != 0 || originalLocal.minute != 0))) {
      targetDateTime = DateTime(
        dropTime.year,
        dropTime.month,
        dropTime.day,
        originalLocal.hour,
        originalLocal.minute,
        originalLocal.second,
      );
    }

    if (originalLocal.year == targetDateTime.year &&
        originalLocal.month == targetDateTime.month &&
        originalLocal.day == targetDateTime.day &&
        originalLocal.hour == targetDateTime.hour &&
        originalLocal.minute == targetDateTime.minute) {
      return;
    }

    final success = await Core.historicoController.updateHistoricoDate(
      itemId,
      targetDateTime,
    );

    if (mounted) {
      final formattedDate =
          '${targetDateTime.day.toString().padLeft(2, '0')}/${targetDateTime.month.toString().padLeft(2, '0')} às ${targetDateTime.hour.toString().padLeft(2, '0')}:${targetDateTime.minute.toString().padLeft(2, '0')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Execução reagendada para $formattedDate'
                : 'Erro ao reagendar execução.',
          ),
          backgroundColor:
              success ? AppColors.pastelSuccess : AppColors.pastelError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Future<void> _handlePickNewDateTime(
    BuildContext context,
    HistoricoItemModel item,
  ) async {
    final DateTime initialDate = item.createdAt.toLocal();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !context.mounted) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !context.mounted) return;

    final DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newDateTime.isAtSameMomentAs(initialDate)) return;

    final success = await Core.historicoController.updateHistoricoDate(
      item.id,
      newDateTime,
    );

    if (context.mounted) {
      final formattedDate =
          '${newDateTime.day.toString().padLeft(2, '0')}/${newDateTime.month.toString().padLeft(2, '0')} às ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Data da execução alterada para $formattedDate'
                : 'Erro ao alterar data da execução.',
          ),
          backgroundColor:
              success ? AppColors.pastelSuccess : AppColors.pastelError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  void _showHistoricoDetailsModal(
    BuildContext context,
    HistoricoItemModel item,
  ) {
    final dateStr =
        '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year} às ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
    final bool isNegativo =
        item.tarefasEHabitos.tarefasHabitosQtd.any((q) => q.valor < 0);
    final String tipoLabel = item.tarefasEHabitos.tipo == 'habito'
        ? (isNegativo ? 'Hábito Negativo (Recaída)' : 'Hábito')
        : 'Tarefa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.tarefasEHabitos.nome.isNotEmpty
                            ? item.tarefasEHabitos.nome
                            : tipoLabel,
                        style: (Theme.of(context).textTheme.titleMedium ??
                                const TextStyle())
                            .copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isNegativo
                            ? AppColors.pastelErrorContainer
                            : (item.tarefasEHabitos.tipo == 'habito'
                                ? AppColors.primaryContainerLight
                                : AppColors.secondaryContainerLight),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        tipoLabel,
                        style: (Theme.of(context).textTheme.labelSmall ??
                                const TextStyle())
                            .copyWith(
                          color: isNegativo
                              ? AppColors.onPastelErrorContainer
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isNegativo
                              ? 'Recaída em: $dateStr'
                              : 'Executado em: $dateStr',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(modalContext).pop();
                    await _handlePickNewDateTime(context, item);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Alterar data e horário'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    _showDeleteDialog(context, item);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.pastelError,
                  ),
                  label: const Text(
                    'Excluir registro',
                    style: TextStyle(color: AppColors.pastelError),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.pastelError),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        );
      },
    );
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
                    SnackBar(
                      content: const Text('Registro removido com sucesso!'),
                      backgroundColor: AppColors.pastelSuccess,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Remover', style: TextStyle(color: AppColors.pastelError)),
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
                    allowDragAndDrop: true,
                    onDragEnd: _handleAppointmentDragEnd,
                    showDatePickerButton: true,
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      minimumAppointmentDuration: Duration(minutes: 30),
                      timeFormat: 'HH:mm',
                    ),
                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
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
                          final item = historyList.cast<HistoricoItemModel?>().firstWhere(
                            (el) => el?.id == itemId,
                            orElse: () => null,
                          );
                          if (item != null) {
                            _showHistoricoDetailsModal(context, item);
                          }
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
