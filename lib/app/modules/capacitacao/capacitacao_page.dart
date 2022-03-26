import 'dart:math';
import 'package:circle_list/circle_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ppvdigital/app/modules/capacitacao/capacitacao_store.dart';

class CapacitacaoPage extends StatefulWidget {
  const CapacitacaoPage({
    Key? key,
    this.title = 'Capacitação Técnica',
  }) : super(key: key);
  
  final String title;

  @override
  _CapacitacaoPageState createState() => _CapacitacaoPageState();
}

class _CapacitacaoPageState extends ModularState<CapacitacaoPage, CapacitacaoStore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircleList(
          innerRadius: 0,
          rotateMode: RotateMode.stopRotate,
          showInitialAnimation: true,
          origin: Offset.zero,
          children: List.generate(2, (index) {
            String dimensionName = '';
            String routeName = '';
            
            switch (index) {
              case 1:
                dimensionName = 'Tarefas';
                routeName = '/capacitacao-tecnica/tarefas';
              break;
              default:
                dimensionName = 'Planejamento financeiro';
                routeName = '/capacitacao-tecnica/financas';
            }

            return InkWell(
              onTap: () {
                Modular.to.pushNamed(routeName);
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Color(Random().nextInt(0xffffffff)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    dimensionName,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
