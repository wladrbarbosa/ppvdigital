import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ppvdigital/app/capacitacao/tarefas_habitos/dashboard_logic.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/design_system/design_system.dart';
import 'package:ppvdigital/models/historico_item_model.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<HistoricoItemModel> _historico = [];
  StreamSubscription<List<HistoricoItemModel>>? _historicoSub;
  bool _isLoading = true;
  bool _filtersLoaded = false;

  // Legend Toggles
  bool _showPlanned = true;
  bool _showExecuted = true;
  bool _showCompletionRate = true;

  final Set<String> _hiddenGoalCycles = {};
  final Set<String> _hiddenGoalCategories = {};
  final Set<String> _hiddenAttentionCategories = {};

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _initData();
  }

  @override
  void dispose() {
    _historicoSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    try {
      final jsonStr = await Core.database.getSetting('dashboard_filters');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            if (data['showPlanned'] is bool) {
              _showPlanned = data['showPlanned'] as bool;
            }
            if (data['showExecuted'] is bool) {
              _showExecuted = data['showExecuted'] as bool;
            }
            if (data['showCompletionRate'] is bool) {
              _showCompletionRate = data['showCompletionRate'] as bool;
            }
            if (data['hiddenGoalCycles'] is List) {
              _hiddenGoalCycles.clear();
              _hiddenGoalCycles.addAll(
                (data['hiddenGoalCycles'] as List).cast<String>(),
              );
            }
            if (data['hiddenGoalCategories'] is List) {
              _hiddenGoalCategories.clear();
              _hiddenGoalCategories.addAll(
                (data['hiddenGoalCategories'] as List).cast<String>(),
              );
            }
            if (data['hiddenAttentionCategories'] is List) {
              _hiddenAttentionCategories.clear();
              _hiddenAttentionCategories.addAll(
                (data['hiddenAttentionCategories'] as List).cast<String>(),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard filters: $e');
    } finally {
      if (mounted) {
        setState(() {
          _filtersLoaded = true;
        });
      }
    }
  }

  void _persistFilters() {
    if (!_filtersLoaded) return;
    try {
      final map = {
        'showPlanned': _showPlanned,
        'showExecuted': _showExecuted,
        'showCompletionRate': _showCompletionRate,
        'hiddenGoalCycles': _hiddenGoalCycles.toList(),
        'hiddenGoalCategories': _hiddenGoalCategories.toList(),
        'hiddenAttentionCategories': _hiddenAttentionCategories.toList(),
      };
      Core.database.setSetting('dashboard_filters', json.encode(map));
    } catch (e) {
      debugPrint('Error saving dashboard filters: $e');
    }
  }

  Future<void> _initData() async {
    try {
      await Core.tarefasHabitosController.loadDocuments();
      final userId = Core.loginController.currentUser?.$id ?? '';
      if (userId.isNotEmpty) {
        _historicoSub?.cancel();
        final stream = Core.tarefaHabitoRepository.watchHistorico(
          usuarioId: userId,
        );
        try {
          final initialData = await Core.tarefaHabitoRepository.getHistorico(
            usuarioId: userId,
            forceLocal: true,
          );
          if (mounted) {
            setState(() {
              _historico = initialData;
            });
          }
        } catch (_) {}

        _historicoSub = stream.listen((data) {
          if (mounted) {
            setState(() {
              _historico = data;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data for dashboard: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (context) {
          final isSyncing = Core.tarefasHabitosController.isSyncing;
          final items = Core.tarefasHabitosController.tarefasHabitosList
              .where((i) => !i.arquivado)
              .toList();

          if (_isLoading || (items.isEmpty && isSyncing)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return const Center(child: Text('Nenhum dado para mostrar no momento.'));
          }

          final activeHistorico = _historico
              .where((h) => !h.tarefasEHabitos.arquivado)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCommitmentTimeChart(context, items, activeHistorico),
                const SizedBox(height: 24),
                _buildCategoryGoalProgressBars(context, items, activeHistorico),
                const SizedBox(height: 24),
                _buildCompletionRateChart(context, items, activeHistorico),
                const SizedBox(height: 24),
                _buildCategoryAttentionPieChart(context, items),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatCommitmentMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}min';
  }

  Widget _buildCommitmentTimeChart(
      BuildContext context, List<TarefaHabitoModel> items, List<HistoricoItemModel> historico) {
    final plannedMap = DashboardLogic.getPlannedCommitmentTime(items);
    final executedMap = DashboardLogic.getExecutedCommitmentTime(items, historico);
    final availableMap = DashboardLogic.getAvailableTime();

    final cycles = ['dias', 'semanas', 'meses', 'anos'];
    final labels = ['Dia', 'Semana', 'Mês', 'Ano'];

    final colorPlanned = Theme.of(context).colorScheme.primary;
    const colorExecuted = AppColors.pastelSuccess;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo de Comprometimento vs Disponível',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque na legenda para ocultar/exibir',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
            if (plannedMap['dias'] == 0 && items.any((i) => i.tipo == 'habito' && !i.isHabitoNegativo)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Defina a duração estimada nos seus hábitos para calcular o tempo previsto.',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _showPlanned = !_showPlanned;
                    });
                    _persistFilters();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showPlanned ? 1.0 : 0.4,
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: colorPlanned, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            'Previsto (Hábitos)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: _showPlanned ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _showExecuted = !_showExecuted;
                    });
                    _persistFilters();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showExecuted ? 1.0 : 0.4,
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: colorExecuted, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            'Executado (Hábitos + Tarefas)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: _showExecuted ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final cycle = cycles[group.x];
                        final plannedMin = plannedMap[cycle] ?? 0;
                        final executedMin = executedMap[cycle] ?? 0;
                        final availMin = availableMap[cycle] ?? 1;

                        final plannedPct = (plannedMin / availMin * 100).toStringAsFixed(1);
                        final executedPct = (executedMin / availMin * 100).toStringAsFixed(1);

                        final isPlannedRod = _showPlanned && (rodIndex == 0 || !_showExecuted);
                        final labelText = isPlannedRod
                            ? 'Previsto: ${_formatCommitmentMinutes(plannedMin)} ($plannedPct%)'
                            : 'Executado: ${_formatCommitmentMinutes(executedMin)} ($executedPct%)';

                        return BarTooltipItem(
                          '${labels[group.x]}\n$labelText\nDisponível: ${_formatCommitmentMinutes(availMin)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          if (value == idx.toDouble() && idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(labels[idx], style: const TextStyle(fontSize: 12)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0%', style: TextStyle(fontSize: 10));
                          if (value == 0.5) return const Text('50%', style: TextStyle(fontSize: 10));
                          if (value == 1.0) return const Text('100%', style: TextStyle(fontSize: 10));
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: cycles.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final String cycle = entry.value;

                    final plannedMin = plannedMap[cycle] ?? 0;
                    final executedMin = executedMap[cycle] ?? 0;
                    final availMin = availableMap[cycle] ?? 1;

                    final valPlanned = (plannedMin / availMin).clamp(0.0, 1.2);
                    final valExecuted = (executedMin / availMin).clamp(0.0, 1.2);

                    return BarChartGroupData(
                      x: idx,
                      barsSpace: 4,
                      barRods: [
                        if (_showPlanned)
                          BarChartRodData(
                            toY: valPlanned,
                            color: colorPlanned,
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        if (_showExecuted)
                          BarChartRodData(
                            toY: valExecuted,
                            color: colorExecuted,
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGoalProgressBars(
      BuildContext context, List<TarefaHabitoModel> items, List<HistoricoItemModel> historico) {
    final categoryList = DashboardLogic.getCategoryProgress(items, historico);

    if (categoryList.isEmpty) {
      return const SizedBox.shrink();
    }

    final cycleKeys = ['dias', 'semanas', 'meses', 'anos'];
    final cycleLabels = {'dias': 'Dia', 'semanas': 'Semana', 'meses': 'Mês', 'anos': 'Ano'};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '% Meta por Categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque em um ciclo ou categoria para ocultar/exibir',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            // Cycle Filter Chips
            Wrap(
              spacing: 8,
              children: cycleKeys.map((key) {
                final isHidden = _hiddenGoalCycles.contains(key);
                return FilterChip(
                  label: Text(cycleLabels[key]!),
                  selected: !isHidden,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _hiddenGoalCycles.remove(key);
                      } else {
                        _hiddenGoalCycles.add(key);
                      }
                    });
                    _persistFilters();
                  },
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryList.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final cat = categoryList[index];
                final isCatHidden = _hiddenGoalCategories.contains(cat.name);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          if (isCatHidden) {
                            _hiddenGoalCategories.remove(cat.name);
                          } else {
                            _hiddenGoalCategories.add(cat.name);
                          }
                        });
                        _persistFilters();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isCatHidden ? 0.4 : 1.0,
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: isCatHidden ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isCatHidden) ...[
                      const SizedBox(height: 12),
                      Column(
                        children: cycleKeys.where((key) => !_hiddenGoalCycles.contains(key)).map((key) {
                          final cycle = cat.cycles[key]!;
                          final percentageText = '${(cycle.percentage * 100).toInt()}%';
                          final executedStr = cycle.totalExecuted % 1 == 0
                              ? cycle.totalExecuted.toInt().toString()
                              : cycle.totalExecuted.toStringAsFixed(1);
                          final goalStr = cycle.totalGoal % 1 == 0
                              ? cycle.totalGoal.toInt().toString()
                              : cycle.totalGoal.toStringAsFixed(1);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    cycle.cycleName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: cycle.percentage,
                                      minHeight: 8,
                                      backgroundColor: cat.color.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    '$percentageText ($executedStr/$goalStr)',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: cat.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateChart(
      BuildContext context, List<TarefaHabitoModel> items, List<HistoricoItemModel> historico) {
    final dailyRates = DashboardLogic.getCompletionRateLast7DaysList(items, historico);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<FlSpot> spots = [];
    for (int i = 0; i < dailyRates.length; i++) {
      spots.add(FlSpot(i.toDouble(), _showCompletionRate ? dailyRates[i].rate : 0.0));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taxa de Conclusão (7 dias)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque na legenda para ocultar/exibir',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _showCompletionRate = !_showCompletionRate;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showCompletionRate ? 1.0 : 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        'Taxa de Conclusão Diária',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: _showCompletionRate ? TextDecoration.none : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (value == idx.toDouble() && idx >= 0 && idx < dailyRates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dailyRates[idx].dateLabel,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 0.2,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: _showCompletionRate,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx >= 0 && idx < dailyRates.length) {
                            final item = dailyRates[idx];
                            return LineTooltipItem(
                              '${item.dateLabel}\nConclusão: ${(item.rate * 100).toStringAsFixed(0)}%\n(${item.completedCount}/${item.totalCount} hábitos)',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 1.0,
                  lineBarsData: [
                    if (_showCompletionRate)
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: primaryColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAttentionPieChart(BuildContext context, List<TarefaHabitoModel> items) {
    final attentionList = DashboardLogic.getCategoryAttentionDistribution(items);

    if (attentionList.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeList = attentionList.where((cat) => !_hiddenAttentionCategories.contains(cat.name)).toList();
    final double activeTotalVal = activeList.fold(0.0, (sum, cat) => sum + cat.totalValue);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Atenção por Categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque na legenda para ocultar/exibir fatias',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: (activeList.isEmpty || activeTotalVal <= 0)
                  ? const Center(child: Text('Nenhuma categoria visível'))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: activeList.map((cat) {
                          return PieChartSectionData(
                            color: cat.color,
                            value: cat.totalValue,
                            showTitle: false,
                            title: '',
                            radius: 80,
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: attentionList.map((cat) {
                final isHidden = _hiddenAttentionCategories.contains(cat.name);
                final pct = (!isHidden && activeTotalVal > 0)
                    ? (cat.totalValue / activeTotalVal * 100).round()
                    : 0;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      if (isHidden) {
                        _hiddenAttentionCategories.remove(cat.name);
                      } else {
                        _hiddenAttentionCategories.add(cat.name);
                      }
                    });
                    _persistFilters();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isHidden ? 0.4 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isHidden ? Colors.grey : cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isHidden ? cat.name : '${cat.name} ($pct%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
