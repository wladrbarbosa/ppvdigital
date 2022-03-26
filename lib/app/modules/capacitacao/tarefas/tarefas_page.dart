import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/categoria_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_feita_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/models/tarefa_model.dart';
import 'package:ppvdigital/app/modules/capacitacao/tarefas/tarefas_store.dart';
import 'package:table_calendar/table_calendar.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({
    Key? key,
    this.title = 'Tarefas',
  }) : super(key: key);
  
  final String title;

  @override
  _TarefasPageState createState() => _TarefasPageState();
}

class _TarefasPageState extends ModularState<TarefasPage, TarefasStore> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 3);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            ListTile(
              title: Text(
              'Tarefas',
              ),
            ),
            ListTile(
              title: Text(
              'Calendário',
              ),
            ),
            ListTile(
              title: Text(
              'Histórico',
              ),
            ),
          ],
        ),
        title: const Text('Tarefas'),
      ),
      body: Observer(
        name: 'tarefas',
        builder: (context) {
          if (store.tarefas.hasError) {
            return Center(
              child: ElevatedButton(
                onPressed: store.getListTarefas,
                child: const Text(
                  'Error',
                ),
              ),
            );
          }

          if (store.tarefas.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<TarefaModel>? tarefasList = store.tarefas.value;

          if (store.historico.hasError) {
            return Center(
              child: ElevatedButton(
                onPressed: store.getHistorico,
                child: const Text(
                  'Error',
                ),
              ),
            );
          }

          if (store.historico.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<TarefaFeitaModel>? historicoList = store.historico.value;

          if (store.categorias.hasError) {
            return Center(
              child: ElevatedButton(
                onPressed: store.getHistorico,
                child: const Text(
                  'Error',
                ),
              ),
            );
          }

          if (store.categorias.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<CategoriaModel>? categoriasList = store.categorias.value;
          final ScrollController _tarefasListController = ScrollController();

          return TabBarView(
            controller: _tabController,
            children: [
              ListView.builder(
                controller: _tarefasListController,
                shrinkWrap: true,
                itemCount: categoriasList!.length,
                itemBuilder: (_, index) {
                  final CategoriaModel model = categoriasList[index];
                  final List<TarefaModel> tarefasModel = tarefasList!.where((el) => el.categoria == model.reference).toList();
                  int totalPontosPorDia = 0;
                  int totalPontosPorSemana = 0;
                  int totalPontosPorMes = 0;
                  int totalPontosPorAno = 0;
                  final List<Widget> tarefasWidgets = [];

                  tarefasModel.forEach((tarefaEl) {
                    totalPontosPorDia += historicoList!.where((historicoEl) => historicoEl.tarefa == tarefaEl.reference && historicoEl.dataHora!.toDate().day == DateTime.now().day).length * tarefaEl.valor;
                    totalPontosPorSemana += historicoList.where((historicoEl) => historicoEl.tarefa == tarefaEl.reference && DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).compareTo(historicoEl.dataHora!.toDate()).abs() <= 7).length * tarefaEl.valor;
                    totalPontosPorMes += historicoList.where((historicoEl) => historicoEl.tarefa == tarefaEl.reference && historicoEl.dataHora!.toDate().month == DateTime.now().month).length * tarefaEl.valor;
                    totalPontosPorAno += historicoList.where((historicoEl) => historicoEl.tarefa == tarefaEl.reference && historicoEl.dataHora!.toDate().year == DateTime.now().year).length * tarefaEl.valor;
                  });

                  tarefasModel.forEach((el) {
                    tarefasWidgets.add(
                      ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${el.valor}',
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Text(
                                el.nome,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showTarefasDialog(el);
                        },
                        leading: IconButton(
                          onPressed: el.delete,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            el.doTarefa(store.tarefaFeitaRepo);
                          },
                          icon: const Icon(
                            Icons.add_task,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  });
                  
                  return ExpansionTile(
                    title: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Nome:',
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                model.nome,
                              ),
                            ),
                          ],
                        ),
                        if (model.minimoDiario == 0) Container() else Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${model.minimoDiario}',
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Diário:',
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 20,
                                child: FAProgressBar(
                                  currentValue: (totalPontosPorDia / model.minimoDiario * 100).toInt(),
                                  displayText: '%',
                                  progressColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (model.minimoSemanal == 0) Container() else Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${model.minimoSemanal}',
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Semanal:',
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 20,
                                child: FAProgressBar(
                                  currentValue: (totalPontosPorSemana / model.minimoSemanal * 100).toInt(),
                                  displayText: '%',
                                  progressColor: Colors.yellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (model.minimoMensal == 0) Container() else Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${model.minimoMensal}',
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Mensal:',
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 20,
                                child: FAProgressBar(
                                  currentValue: (totalPontosPorMes / model.minimoMensal * 100).toInt(),
                                  displayText: '%',
                                  progressColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (model.minimoAnual == 0) Container() else Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${model.minimoAnual}',
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Anual:',
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: SizedBox(
                                height: 20,
                                child: FAProgressBar(
                                  currentValue: (totalPontosPorAno / model.minimoAnual * 100).toInt(),
                                  displayText: '%',
                                  progressColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    leading: IconButton(
                      onPressed: model.delete,
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        _showCategoriasDialog(model);
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.yellow,
                      ),
                    ),
                    children: tarefasWidgets,
                  );
                },
              ),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365 * 5)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
                locale: 'pt_BR',
                focusedDay: DateTime.now(),
              ),
              Column(
                children: [
                  ListTile(
                    title: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Nome',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Data',
                          ),
                        ),
                      ],
                    ),
                    leading: IconButton(
                      onPressed: store.clearHistorico,
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: historicoList!.length,
                    itemBuilder: (_, index) {
                      final TarefaFeitaModel tarefaFeitaModel = historicoList[index];
                      final TarefaModel? tarefaModel = tarefasList!.firstWhereOrNull((el) => el.reference == tarefaFeitaModel.tarefa);
                      
                      if (tarefaModel != null) {
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tarefaModel.nome,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy hh:mm:ss').format(tarefaFeitaModel.dataHora!.toDate()),
                                ),
                              ),
                            ],
                          ),
                          leading: IconButton(
                            onPressed: tarefaFeitaModel.delete,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                          ),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: SpeedDial(
        tooltip: 'Adicionar',
        childrenButtonSize: 100,
        spaceBetweenChildren: 20,
        children: [
          SpeedDialChild(
            child: const Text('Tarefa'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onTap: () => _showTarefasDialog(),
          ),
          SpeedDialChild(
            child: const Text('Categoria'),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            onTap: () => _showCategoriasDialog(),
          ),
        ],
        child: const Icon(Icons.add),
      ),
    );
  }

  Future <void>_showTarefasDialog([TarefaModel? model]) async {
    model ??= TarefaModel();
    final List<CategoriaModel>? categoriasList = await store.getListCategoriasOneShot();
    final Observable<DocumentReference?> selCategoria = Observable<DocumentReference?>(model.categoria);
    
    return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(model!.nome.isEmpty ? 'Nova' : 'Edição'),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                const Spacer(),
                TextFormField(
                  initialValue: model.nome,
                  onChanged: (value) => model!.nome = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nome...',
                  ),
                ),
                const Spacer(),
                TextFormField(
                  initialValue: model.valor.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => model!.valor = int.tryParse(value) ?? 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Valor...',
                  ),
                ),
                const Spacer(),
                Observer(
                  builder: (obsContext) {
                    return DropdownButton<DocumentReference>(
                      value: selCategoria.value,
                      isExpanded: true,
                      onChanged: (value) {
                        runInAction(() {
                          selCategoria.value = value;
                        });
                      },
                      items: categoriasList!.map<DropdownMenuItem<DocumentReference>>((e) {
                        return DropdownMenuItem<DocumentReference>(
                          value: e.reference,
                          child: Text(
                            e.nome,
                          ),
                        );
                      }).toList(),
                      hint: const Text(
                        'Categoria...',
                      ),
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Modular.to.pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                model!.categoria = selCategoria.value;
                await model.save();
                Modular.to.pop();
              },
              child: const Text('Salvar'),
            )
          ],
        );
      },
    );
  }

  Future<void> _showCategoriasDialog([CategoriaModel? model]) async {
    model ??= CategoriaModel();

    return showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(model!.nome.isEmpty ? 'Nova' : 'Edição'),
          content: SizedBox(
            height: 300,
            child: Column(
              children: [
                const Spacer(),
                TextFormField(
                  initialValue: model.nome,
                  onChanged: (value) => model!.nome = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nome...',
                  ),
                ),
                const Spacer(),
                TextFormField(
                  initialValue: model.minimoDiario.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => model!.minimoDiario = int.tryParse(value) ?? 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Desejo de valor diário...',
                  ),
                ),
                const Spacer(),
                TextFormField(
                  initialValue: model.minimoSemanal.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => model!.minimoSemanal = int.tryParse(value) ?? 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Desejo de valor semanal...',
                  ),
                ),
                const Spacer(),
                TextFormField(
                  initialValue: model.minimoMensal.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => model!.minimoMensal = int.tryParse(value) ?? 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Desejo de valor mensal...',
                  ),
                ),
                const Spacer(),
                TextFormField(
                  initialValue: model.minimoAnual.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => model!.minimoAnual = int.tryParse(value) ?? 0,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Desejo de valor anual...',
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Modular.to.pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await model!.save();
                Modular.to.pop();
              },
              child: const Text('Salvar'),
            )
          ],
        );
      },
    );
  }
}
