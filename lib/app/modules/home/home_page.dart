import 'dart:math';
import 'package:circle_list/circle_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ppvdigital/app/modules/home/home_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    this.title = 'Home',
  }) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ModularState<HomePage, HomeStore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircleList(
          innerRadius: 0,
          rotateMode: RotateMode.stopRotate,
          showInitialAnimation: true,
          origin: Offset.zero,
          children: List.generate(5, (index) {
            String dimensionName = '';
            String routeName = '';
            
            switch (index) {
              case 1:
                dimensionName = 'Eu com o outro';
                routeName = '/integracao';
              break;
              case 2:
                dimensionName = 'Eu com a sociedade';
                routeName = '/conscientizacao-politica';
              break;
              case 3:
                dimensionName = 'Eu com Deus';
                routeName = '/teologica-teologal';
              break;
              case 4:
                dimensionName = 'Eu com a ação';
                routeName = '/capacitacao-tecnica';
              break;
              default:
                dimensionName = 'Eu comigo';
                routeName = '/personalizacao';
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
