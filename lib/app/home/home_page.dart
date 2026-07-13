import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title = 'Home'});

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int touchedIndex = -1;

  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Eu com Deus',
      'color': Colors.amber,
      'description': 'Espiritualidade, fé e propósito de vida.',
    },
    {
      'title': 'Eu com a Sociedade',
      'color': Colors.red,
      'description': 'Relações sociais, comunidade e impacto no mundo.',
    },
    {
      'title': 'Eu com a Capacitação Técnica',
      'color': Colors.deepPurple,
      'description': 'Gestão de tarefas, hábitos e finanças pessoais.',
      'available': true,
      'route': '/capacitacao',
    },
    {
      'title': 'Eu Comigo',
      'color': Colors.blue,
      'description': 'Autoconhecimento, saúde mental e crescimento pessoal.',
    },
    {
      'title': 'Eu com o Outro',
      'color': Colors.green,
      'description': 'Família, amizades e relacionamentos mais próximos.',
    },
  ];

  void _handleCategoryAction(int index) {
    final cat = categories[index];
    if (cat['available'] == true && cat['route'] != null) {
      Routefly.navigate(cat['route'] as String);
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Módulo "${cat['title']}" está em desenvolvimento.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seapruma Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          // Determine chart size and slice radius based on screen type
          final double chartSize = isMobile ? 220.0 : 300.0;
          final double normalRadius = isMobile ? 65.0 : 90.0;
          final double touchedRadius = isMobile ? 80.0 : 105.0;

          final List<PieChartSectionData> sliceList = List.generate(
            categories.length,
            (i) {
              final isTouched = touchedIndex == i;
              final cat = categories[i];
              return PieChartSectionData(
                radius: isTouched ? touchedRadius : normalRadius,
                showTitle: false, // Clean look, title in legend/list
                color: cat['color'] as Color,
                value: 20.0, // Equal sections
                badgeWidget: isTouched
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          cat['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                badgePositionPercentageOffset: 0.9,
              );
            },
          );

          final chartWidget = Center(
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;

                        if (event is FlTapUpEvent) {
                          if (touchedIndex >= 0) {
                            _handleCategoryAction(touchedIndex);
                          }
                        }
                      });
                    },
                  ),
                  sections: sliceList,
                  sectionsSpace: 3,
                  centerSpaceRadius: isMobile ? 35.0 : 50.0,
                ),
              ),
            ),
          );

          final listWidget = ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected = touchedIndex == i;
              final Color baseColor = cat['color'] as Color;

              return MouseRegion(
                onEnter: (_) => setState(() => touchedIndex = i),
                onExit: (_) => setState(() => touchedIndex = -1),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? baseColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleCategoryAction(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      cat['title'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? baseColor : null,
                                      ),
                                    ),
                                    if (cat['available'] == true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: baseColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Ativo',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: baseColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat['description'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: isSelected
                                ? baseColor
                                : Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );

          if (isMobile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Selecione uma área para navegar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  chartWidget,
                  const SizedBox(height: 32),
                  listWidget,
                ],
              ),
            );
          } else {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Selecione uma área para navegar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                          chartWidget,
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(child: listWidget),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
