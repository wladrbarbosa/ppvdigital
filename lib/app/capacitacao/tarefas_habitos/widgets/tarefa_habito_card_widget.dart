import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/lista_habitos_tarefas_widget.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

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
      return '${(qtd.vezesPraticado as double).roundDouble(1)} / ${qtd.metaVezes} vezes';
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
    final categoria =
        item.tarefasHabitosQtd.firstOrNull?.categoriasTarefasHabitos;

    return Observer(
      builder: (context) {
        return Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: item.tipo == 'habito'
                  ? habitColor.withValues(alpha: 0.4)
                  : taskColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
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
                            const SizedBox(width: 4.0),
                            if (item.duration != null &&
                                item.duration! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: item.tipo == 'habito'
                                      ? habitColor.withValues(alpha: 0.15)
                                      : taskColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: item.tipo == 'habito'
                                        ? habitColor.withValues(alpha: 0.4)
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
                                          ? habitColor
                                          : taskColor,
                                    ),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      _formatDuration(item.duration),
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        color: item.tipo == 'habito'
                                            ? habitColor
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
                              const Icon(
                                Icons.calendar_today,
                                size: 11.0,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${item.agendamento!.day.toString().padLeft(2, '0')}/${item.agendamento!.month.toString().padLeft(2, '0')} ${item.agendamento!.hour.toString().padLeft(2, '0')}:${item.agendamento!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 10.0,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2.0),
                        if (item.tipo == 'habito')
                          Text(
                            _getProgressText(item),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
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
                          : Icons.add_circle,
                      size: 32.0,
                      color: item.tipo == 'habito' ? habitColor : taskColor,
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
