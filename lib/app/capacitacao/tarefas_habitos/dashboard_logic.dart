import 'package:flutter/material.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

class CycleProgressData {
  CycleProgressData({
    required this.cycleName,
    required this.cycleKey,
    required this.totalGoal,
    required this.totalExecuted,
  });

  final String cycleName;
  final String cycleKey;
  final int totalGoal;
  final num totalExecuted;

  double get percentage =>
      totalGoal > 0 ? (totalExecuted / totalGoal).clamp(0.0, 1.0) : 0.0;
}

class CategoryProgressData {
  CategoryProgressData({
    required this.name,
    required this.color,
    required this.cycles,
  });

  final String name;
  final Color color;
  final Map<String, CycleProgressData> cycles;

  int get totalGoal => cycles.values.fold(0, (sum, c) => sum + c.totalGoal);
  num get totalExecuted =>
      cycles.values.fold(0, (sum, c) => sum + c.totalExecuted);
  double get percentage =>
      totalGoal > 0 ? (totalExecuted / totalGoal).clamp(0.0, 1.0) : 0.0;
}

class CategoryAttentionData {
  CategoryAttentionData({
    required this.name,
    required this.color,
    required this.totalValue,
  });

  final String name;
  final Color color;
  final double totalValue;
}

class DailyCompletionRate {
  DailyCompletionRate({
    required this.date,
    required this.rate,
    required this.completedCount,
    required this.totalCount,
  });

  final DateTime date;
  final double rate;
  final int completedCount;
  final int totalCount;

  String get dateLabel => '${date.day}/${date.month}';
}

class DashboardLogic {
  /// Calculates planned commitment time (Tempo Previsto) in minutes, grouped by current cycle.
  /// Considers ONLY habits (item.tipo == 'habito').
  /// Scales daily habits into week/month/year, weekly habits into month/year, etc.
  static Map<String, int> getPlannedCommitmentTime(
    List<TarefaHabitoModel> items,
  ) {
    final Map<String, int> planned = {
      'dias': 0,
      'semanas': 0,
      'meses': 0,
      'anos': 0,
    };

    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (final item in items) {
      if (item.tipo != 'habito' ||
          item.duration == null ||
          item.duration! <= 0) {
        continue;
      }
      if (item.tarefasHabitosQtd.isEmpty) continue;

      for (final qtd in item.tarefasHabitosQtd) {
        final int baseMinutes = item.duration! * qtd.metaVezes;
        final String cycle = qtd.reiniciaEmTipo;

        switch (cycle) {
          case 'dias':
            planned['dias'] = planned['dias']! + baseMinutes;
            planned['semanas'] = planned['semanas']! + (baseMinutes * 7);
            planned['meses'] = planned['meses']! + (baseMinutes * daysInMonth);
            planned['anos'] = planned['anos']! + (baseMinutes * 365);

          case 'semanas':
            planned['dias'] = planned['dias']! + (baseMinutes / 7).round();
            planned['semanas'] = planned['semanas']! + baseMinutes;
            planned['meses'] = planned['meses']! + (baseMinutes * 4);
            planned['anos'] = planned['anos']! + (baseMinutes * 52);

          case 'meses':
            planned['dias'] =
                planned['dias']! + (baseMinutes / daysInMonth).round();
            planned['semanas'] =
                planned['semanas']! + (baseMinutes / 4).round();
            planned['meses'] = planned['meses']! + baseMinutes;
            planned['anos'] = planned['anos']! + (baseMinutes * 12);

          case 'anos':
            planned['anos'] = planned['anos']! + baseMinutes;
        }
      }
    }

    return planned;
  }

  /// Calculates executed commitment time (Tempo Executado) in minutes strictly within the current cycle.
  static Map<String, int> getExecutedCommitmentTime(
    List<TarefaHabitoModel> items, [
    List<HistoricoItemModel>? historico,
  ]) {
    final DateTime now = DateTime.now();

    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    final DateTime startOfMonth = DateTime(now.year, now.month);
    final DateTime endOfMonth = DateTime(now.year, now.month + 1);

    final DateTime startOfYear = DateTime(now.year);
    final DateTime endOfYear = DateTime(now.year + 1);

    int getExecutedForRange(DateTime start, DateTime end) {
      if (historico != null && historico.isNotEmpty) {
        int total = 0;
        final DateTime minStart = start.subtract(
          const Duration(milliseconds: 1),
        );
        for (final h in historico) {
          if (h.createdAt.isAfter(minStart) && h.createdAt.isBefore(end)) {
            total += h.tarefasEHabitos.duration ?? 30;
          }
        }
        return total;
      }

      int total = 0;
      for (final item in items) {
        final int dur = item.duration ?? 30;
        if (item.tipo == 'habito') {
          for (final qtd in item.tarefasHabitosQtd) {
            total += (dur * qtd.vezesPraticado).toInt();
          }
        } else if (item.tipo == 'tarefa' && item.concluida) {
          total += dur;
        }
      }
      return total;
    }

    return {
      'dias': getExecutedForRange(startOfDay, endOfDay),
      'semanas': getExecutedForRange(startOfWeek, endOfWeek),
      'meses': getExecutedForRange(startOfMonth, endOfMonth),
      'anos': getExecutedForRange(startOfYear, endOfYear),
    };
  }

  /// Calculates available time per cycle in minutes
  static Map<String, int> getAvailableTime() {
    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int daysInYear =
        ((now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0)
        ? 366
        : 365;

    return {
      'dias': 24 * 60,
      'semanas': 7 * 24 * 60,
      'meses': daysInMonth * 24 * 60,
      'anos': daysInYear * 24 * 60,
    };
  }

  /// Backward compatible wrapper for legacy calls
  static Map<String, int> getTotalCommitmentTime(
    List<TarefaHabitoModel> items,
  ) {
    return getPlannedCommitmentTime(items);
  }

  /// Calculates category progress (% Meta por Categoria) broken down into 4 cycle columns (Dia, Semana, Mês, Ano).
  /// Larger cycle goals cover smaller cycles, and executed bars reflect executions strictly within each current cycle range.
  static List<CategoryProgressData> getCategoryProgress(
    List<TarefaHabitoModel> items, [
    List<HistoricoItemModel>? historico,
  ]) {
    final Map<String, CategoryProgressData> map = {};

    final defaultColors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.amber,
    ];

    int colorIdx = 0;
    final DateTime now = DateTime.now();

    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    final DateTime startOfMonth = DateTime(now.year, now.month);
    final DateTime endOfMonth = DateTime(now.year, now.month + 1);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final DateTime startOfYear = DateTime(now.year);
    final DateTime endOfYear = DateTime(now.year + 1);

    final Map<String, Map<String, int>> baseGoals = {};
    final Map<String, Color> categoryColors = {};

    for (final item in items) {
      if (item.tipo == 'habito') {
        if (item.tarefasHabitosQtd.isEmpty) continue;

        for (final qtd in item.tarefasHabitosQtd) {
          final cat = qtd.categoriasTarefasHabitos;
          final catName = cat?.nome ?? 'Sem Categoria';
          final catColor =
              cat?.cor ?? defaultColors[colorIdx % defaultColors.length];

          if (!categoryColors.containsKey(catName)) {
            categoryColors[catName] = catColor;
            baseGoals[catName] = {
              'dias': 0,
              'semanas': 0,
              'meses': 0,
              'anos': 0,
            };
            colorIdx++;
          }

          final String cycleKey = qtd.reiniciaEmTipo;
          baseGoals[catName]![cycleKey] =
              (baseGoals[catName]![cycleKey] ?? 0) + qtd.metaVezes;
        }
      }
    }

    num getExecutedForCategoryAndRange(
      String categoryName,
      DateTime start,
      DateTime end,
    ) {
      num executed = 0;
      final DateTime minStart = start.subtract(const Duration(milliseconds: 1));

      if (historico != null && historico.isNotEmpty) {
        for (final h in historico) {
          if (h.createdAt.isAfter(minStart) && h.createdAt.isBefore(end)) {
            final habit = h.tarefasEHabitos;
            for (final qtd in habit.tarefasHabitosQtd) {
              final catName =
                  qtd.categoriasTarefasHabitos?.nome ?? 'Sem Categoria';
              if (catName == categoryName) {
                executed += (qtd.valor > 0 ? qtd.valor : 1.0);
              }
            }
            if (habit.tarefasHabitosQtd.isEmpty &&
                categoryName == 'Sem Categoria') {
              executed += 1.0;
            }
          }
        }
      } else {
        for (final item in items) {
          if (item.tipo == 'habito') {
            for (final qtd in item.tarefasHabitosQtd) {
              final catName =
                  qtd.categoriasTarefasHabitos?.nome ?? 'Sem Categoria';
              if (catName == categoryName) {
                executed +=
                    qtd.vezesPraticado * (qtd.valor > 0 ? qtd.valor : 1.0);
              }
            }
          } else if (item.tipo == 'tarefa' && item.concluida) {
            if (item.tarefasHabitosQtd.isEmpty &&
                categoryName == 'Sem Categoria') {
              executed += 1.0;
            } else {
              for (final qtd in item.tarefasHabitosQtd) {
                final catName =
                    qtd.categoriasTarefasHabitos?.nome ?? 'Sem Categoria';
                if (catName == categoryName) {
                  executed += (qtd.valor > 0 ? qtd.valor : 1.0);
                }
              }
            }
          }
        }
      }
      return executed;
    }

    for (final catName in baseGoals.keys) {
      final Color catColor = categoryColors[catName]!;
      final bg = baseGoals[catName]!;

      final int baseDias = bg['dias']!;
      final int baseSemanas = bg['semanas']!;
      final int baseMeses = bg['meses']!;
      final int baseAnos = bg['anos']!;

      final int goalDias =
          baseDias +
          (baseSemanas / 7).round() +
          (baseMeses / daysInMonth).round();
      final int goalSemanas =
          (baseDias * 7) + baseSemanas + (baseMeses / 4).round();
      final int goalMeses =
          (baseDias * daysInMonth) +
          (baseSemanas * 4) +
          baseMeses +
          (baseAnos / 12).round();
      final int goalAnos =
          (baseDias * 365) + (baseSemanas * 52) + (baseMeses * 12) + baseAnos;

      final num execDias = getExecutedForCategoryAndRange(
        catName,
        startOfDay,
        endOfDay,
      );
      final num execSemanas = getExecutedForCategoryAndRange(
        catName,
        startOfWeek,
        endOfWeek,
      );
      final num execMeses = getExecutedForCategoryAndRange(
        catName,
        startOfMonth,
        endOfMonth,
      );
      final num execAnos = getExecutedForCategoryAndRange(
        catName,
        startOfYear,
        endOfYear,
      );

      map[catName] = CategoryProgressData(
        name: catName,
        color: catColor,
        cycles: {
          'dias': CycleProgressData(
            cycleName: 'Dia',
            cycleKey: 'dias',
            totalGoal: goalDias,
            totalExecuted: execDias,
          ),
          'semanas': CycleProgressData(
            cycleName: 'Semana',
            cycleKey: 'semanas',
            totalGoal: goalSemanas,
            totalExecuted: execSemanas,
          ),
          'meses': CycleProgressData(
            cycleName: 'Mês',
            cycleKey: 'meses',
            totalGoal: goalMeses,
            totalExecuted: execMeses,
          ),
          'anos': CycleProgressData(
            cycleName: 'Ano',
            cycleKey: 'anos',
            totalGoal: goalAnos,
            totalExecuted: execAnos,
          ),
        },
      );
    }

    return map.values.toList();
  }

  /// Calculates distribution of registered attention per category based on the sum of values
  /// of registered tasks and habits per category.
  static List<CategoryAttentionData> getCategoryAttentionDistribution(
    List<TarefaHabitoModel> items,
  ) {
    final Map<String, CategoryAttentionData> map = {};

    final defaultColors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.amber,
    ];

    int colorIdx = 0;

    for (final item in items) {
      if (item.tarefasHabitosQtd.isEmpty) {
        const catName = 'Sem Categoria';
        final catColor = defaultColors[colorIdx % defaultColors.length];
        const double itemVal = 1.0;

        if (!map.containsKey(catName)) {
          map[catName] = CategoryAttentionData(
            name: catName,
            color: catColor,
            totalValue: 0,
          );
          colorIdx++;
        }

        final current = map[catName]!;
        map[catName] = CategoryAttentionData(
          name: catName,
          color: current.color,
          totalValue: current.totalValue + itemVal,
        );
        continue;
      }

      for (final qtd in item.tarefasHabitosQtd) {
        final cat = qtd.categoriasTarefasHabitos;
        final catName = cat?.nome ?? 'Sem Categoria';
        final catColor =
            cat?.cor ?? defaultColors[colorIdx % defaultColors.length];

        final double itemVal = (qtd.valor > 0 ? qtd.valor : 1.0).toDouble();

        if (!map.containsKey(catName)) {
          map[catName] = CategoryAttentionData(
            name: catName,
            color: catColor,
            totalValue: 0,
          );
          colorIdx++;
        }

        final current = map[catName]!;
        map[catName] = CategoryAttentionData(
          name: catName,
          color: current.color,
          totalValue: current.totalValue + itemVal,
        );
      }
    }

    return map.values.toList();
  }

  /// Legacy helper returning Map<String, double>
  static Map<String, double> getCompletionPercentageByCategory(
    List<TarefaHabitoModel> items,
  ) {
    final list = getCategoryProgress(items);
    final Map<String, double> result = {};
    for (final item in list) {
      result[item.name] = item.percentage;
    }
    return result;
  }

  /// Returns completion rates for the last 7 days as a list of DailyCompletionRate objects.
  /// Index 0 is 6 days ago, Index 6 is TODAY (current day).
  static List<DailyCompletionRate> getCompletionRateLast7DaysList(
    List<TarefaHabitoModel> items,
    List<HistoricoItemModel> historico,
  ) {
    final List<DailyCompletionRate> list = [];
    final DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final DateTime date = now.subtract(Duration(days: i));

      int completedOnDate = 0;
      int totalHabits = 0;

      for (final item in items) {
        if (item.tipo == 'habito' && item.tarefasHabitosQtd.isNotEmpty) {
          totalHabits++;
          final bool wasCompletedOnDate = historico.any(
            (h) =>
                h.tarefasEHabitos.id == item.id &&
                h.createdAt.year == date.year &&
                h.createdAt.month == date.month &&
                h.createdAt.day == date.day,
          );
          if (wasCompletedOnDate) {
            completedOnDate++;
          }
        }
      }

      final double rate = totalHabits > 0
          ? (completedOnDate / totalHabits)
          : 0.0;
      list.add(
        DailyCompletionRate(
          date: date,
          rate: rate,
          completedCount: completedOnDate,
          totalCount: totalHabits,
        ),
      );
    }

    return list;
  }

  /// Gets completion rate over the last 7 days as a Map (Day of Month -> Rate).
  static Map<int, double> getCompletionRateLast7Days(
    List<TarefaHabitoModel> items,
    List<HistoricoItemModel> historico,
  ) {
    final list = getCompletionRateLast7DaysList(items, historico);
    final Map<int, double> rates = {};
    for (final item in list) {
      rates[item.date.day] = item.rate;
    }
    return rates;
  }

  /// Calculates distribution of habits vs tasks
  static Map<String, int> getHabitTaskDistribution(
    List<TarefaHabitoModel> items,
  ) {
    int habits = 0;
    int tasks = 0;

    for (final item in items) {
      if (item.concluida) continue;

      if (item.tipo == 'habito') {
        habits++;
      } else if (item.tipo == 'tarefa') {
        tasks++;
      }
    }

    return {'Hábitos': habits, 'Tarefas': tasks};
  }
}
