import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.title = 'Home',
  });

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width / 2;
    final double height = MediaQuery.of(context).size.height / 2;
    final double smallestSize = width < height ? width : height;
    final List<PieChartSectionData> sliceList = <PieChartSectionData>[
      PieChartSectionData(
        radius: smallestSize * (touchedIndex == 0 ? 0.9 : 1),
        showTitle: true,
        title: 'Eu com Deus',
        color: Colors.amber,
      ),
      PieChartSectionData(
        radius: smallestSize * (touchedIndex == 1 ? 0.9 : 1),
        showTitle: true,
        title: 'Eu com a Sociedade',
        color: Colors.red,
      ),
      PieChartSectionData(
        radius: smallestSize * (touchedIndex == 2 ? 0.9 : 1),
        showTitle: true,
        title: 'Eu com a Capacitação Técnica',
        color: Colors.deepPurple,
      ),
      PieChartSectionData(
        radius: smallestSize * (touchedIndex == 3 ? 0.9 : 1),
        showTitle: true,
        title: 'Eu Comigo',
        color: Colors.blue,
      ),
      PieChartSectionData(
        radius: smallestSize * (touchedIndex == 4 ? 0.9 : 1),
        showTitle: true,
        title: 'Eu com o Outro',
        color: Colors.green,
      ),
    ];

    return Scaffold(
      body: Center(
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    if (touchedIndex >= 0) {
                      switch (touchedIndex) {
                        case 1:
                          
                        break;
                        case 2:
                          Routefly.navigate(routePaths.capacitacao.path);
                        case 3:
                          
                        break;
                        case 4:
                          
                        break;
                        default:
                      }
                    }
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            titleSunbeamLayout: true,
            sections: sliceList,
          ),
        ),
      ),
    );
  }
}
