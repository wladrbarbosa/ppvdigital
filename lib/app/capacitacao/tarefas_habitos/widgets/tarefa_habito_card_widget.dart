import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/util.dart';

class TarefaHabitoCardWidget extends StatelessWidget {
  const TarefaHabitoCardWidget({
    super.key,
    required this.item,
    required this.habitColor,
    required this.taskColor,
    required this.onTap,
    required this.onActionPressed,
  });
  final TarefaHabitoModel item;
  final Color habitColor;
  final Color taskColor;
  final VoidCallback onTap;
  final VoidCallback onActionPressed;

  String _getProgressText(TarefaHabitoModel item) {
    if (item.tarefasHabitosQtd.isEmpty) return 'Sem metas';
    if (item.tarefasHabitosQtd.length == 1) {
      final qtd = item.tarefasHabitosQtd.first;
      return '${qtd.vezesPraticado.toPtBr(compactIfInteger: true)} / ${qtd.metaVezes} vezes';
    }
    final completedCount = item.tarefasHabitosQtd
        .where((el) => el.vezesPraticado >= el.metaVezes)
        .length;
    return '$completedCount / ${item.tarefasHabitosQtd.length} metas';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (hours > 0) {
      if (mins > 0) {
        return '${hours}h${mins}m';
      } else {
        return '${hours}h';
      }
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final rawCat =
            item.tarefasHabitosQtd.firstOrNull?.categoriasTarefasHabitos;
        final catId = rawCat?.id;
        final liveCategories = Core.maybeCategoriasController?.categoriasList;
        final liveCat = (catId != null && catId.isNotEmpty && liveCategories != null)
            ? liveCategories
                .cast<CategoriasTarefasHabitosModel?>()
                .firstWhere((c) => c?.id == catId, orElse: () => null)
            : null;
        final categoria = liveCat ?? rawCat;

        final bool isNegativeHabit =
            item.tipo == 'habito' && item.tarefasHabitosQtd.any((q) => q.valor < 0);

        final Color effectiveHabitColor =
            isNegativeHabit ? AppColors.pastelError : habitColor;

        return Card(
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedLg,
            side: BorderSide(
              color: item.tipo == 'habito'
                  ? effectiveHabitColor.withValues(alpha: 0.35)
                  : taskColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          color: Theme.of(context).cardTheme.color,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.mdSm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (item.arquivado) ...[
                                    const Icon(
                                      Icons.archive_outlined,
                                      size: 13.0,
                                      color: AppColors.pastelWarning,
                                    ),
                                    const SizedBox(width: 4.0),
                                  ],
                                  Expanded(
                                    child: Text(
                                      item.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4.0),
                            if (isNegativeHabit) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelErrorContainer,
                                  borderRadius: AppRadius.roundedSm,
                                  border: Border.all(
                                    color: AppColors.pastelError.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  'Negativo',
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onPastelErrorContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                            ],
                            if (item.duration != null &&
                                item.duration! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: item.tipo == 'habito'
                                      ? effectiveHabitColor.withValues(alpha: 0.15)
                                      : taskColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: item.tipo == 'habito'
                                        ? effectiveHabitColor.withValues(alpha: 0.4)
                                        : taskColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 10.0,
                                      color: item.tipo == 'habito'
                                          ? effectiveHabitColor
                                          : taskColor,
                                    ),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      _formatDuration(item.duration),
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        color: item.tipo == 'habito'
                                            ? effectiveHabitColor
                                            : taskColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.tipo == 'tarefa' && categoria != null) ...[
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: categoria.cor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.0),
                                  border: Border.all(
                                    color: categoria.cor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  categoria.nome,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                    color: categoria.cor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2.0),
                        if (item.tipo == 'tarefa' &&
                            item.agendamento != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 11.0,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${item.agendamento!.day.toString().padLeft(2, '0')}/${item.agendamento!.month.toString().padLeft(2, '0')} ${item.agendamento!.hour.toString().padLeft(2, '0')}:${item.agendamento!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2.0),
                        if (item.tipo == 'habito')
                          Text(
                            _getProgressText(item),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onActionPressed,
                    icon: Icon(
                      item.tipo == 'tarefa'
                          ? Icons.check_circle_outline
                          : (isNegativeHabit
                              ? Icons.remove_circle_outline
                              : Icons.add_circle),
                      size: 32.0,
                      color: item.tipo == 'habito'
                          ? effectiveHabitColor
                          : taskColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
