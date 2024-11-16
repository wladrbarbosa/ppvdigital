import 'package:flutter/material.dart';

class CapacitacaoPage extends StatefulWidget {
  const CapacitacaoPage({
    super.key,
    this.title = 'Capacitação Técnica',
  });
  
  final String title;

  @override
  _CapacitacaoPageState createState() => _CapacitacaoPageState();
}

class _CapacitacaoPageState extends State<CapacitacaoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GridView.count(
          crossAxisCount: 5,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hábitos',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text(
                      'Controle os seus hábitos',
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Finanças',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text(
                      'Controle os seus gastos e ganhos',
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
}
