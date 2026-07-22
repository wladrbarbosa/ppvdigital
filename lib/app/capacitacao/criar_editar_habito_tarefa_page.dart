import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/tarefas_habitos_model.dart';
import 'package:ppvdigital/util.dart';
import 'package:routefly/routefly.dart';

class MetaItem {
  MetaItem({
    this.id,
    required String metaVezes,
    required String valor,
    required String reiniciaEmQtd,
    required this.reiniciaEmTipo,
    this.selectedCategoryId,
  }) : metaVezesController = TextEditingController(text: metaVezes),
       valorController = TextEditingController(text: valor),
       reiniciaEmQtdController = TextEditingController(text: reiniciaEmQtd);
  String? id;
  final TextEditingController metaVezesController;
  final TextEditingController valorController;
  final TextEditingController reiniciaEmQtdController;
  String reiniciaEmTipo;
  String? selectedCategoryId;

  void dispose() {
    metaVezesController.dispose();
    valorController.dispose();
    reiniciaEmQtdController.dispose();
  }
}

Route routeBuilder(BuildContext context, RouteSettings settings) {
  final args = settings.arguments;
  String? lastRoute;
  TarefaHabitoModel? editingItem;

  if (args is String) {
    lastRoute = args;
  } else if (args is Map) {
    lastRoute = args['lastRoute'] as String?;
    editingItem = args['tarefaHabito'] as TarefaHabitoModel?;
  }

  return DialogRoute(
    context: context,
    settings: settings,
    builder: (context) => PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (lastRoute != null) {
          Routefly.navigate(lastRoute);
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: CriarHabitoTarefaPage(
            editingItem: editingItem,
            lastRoute: lastRoute,
          ),
        ),
      ),
    ),
  );
}

class CriarHabitoTarefaPage extends StatefulWidget {
  const CriarHabitoTarefaPage({super.key, this.editingItem, this.lastRoute});

  final TarefaHabitoModel? editingItem;
  final String? lastRoute;

  @override
  State<CriarHabitoTarefaPage> createState() => _CriarHabitoTarefaPageState();
}

class _CriarHabitoTarefaPageState extends State<CriarHabitoTarefaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _durationController = TextEditingController();
  final List<MetaItem> _metas = [];

  String _tipo = 'habito'; // 'habito' or 'tarefa'
  DateTime? _agendamento;

  @override
  void initState() {
    super.initState();
    Core.categoriasController.loadDocuments();

    if (widget.editingItem != null) {
      final item = widget.editingItem!;
      _nomeController.text = item.nome;
      _tipo = item.tipo;
      _agendamento = item.agendamento;
      _durationController.text = item.duration?.toString() ?? '';

      for (final qtd in item.tarefasHabitosQtd) {
        _metas.add(
          MetaItem(
            id: qtd.id,
            metaVezes: _tipo == 'tarefa' ? '1' : qtd.metaVezes.toString(),
            valor: qtd.valor.toPtBr(compactIfInteger: true),
            reiniciaEmQtd: _tipo == 'tarefa'
                ? '1'
                : qtd.reiniciaEmQtd.toString(),
            reiniciaEmTipo: _tipo == 'tarefa' ? 'dias' : qtd.reiniciaEmTipo,
            selectedCategoryId: qtd.categoriasTarefasHabitos?.id,
          ),
        );
      }
    }

    if (_metas.isEmpty) {
      _metas.add(
        MetaItem(
          metaVezes: '1',
          valor: '1.0',
          reiniciaEmQtd: '1',
          reiniciaEmTipo: 'dias',
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _durationController.dispose();
    for (final meta in _metas) {
      meta.dispose();
    }
    super.dispose();
  }

  Future<void> _selectAgendamento() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _agendamento ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_agendamento ?? DateTime.now()),
    );

    if (pickedTime == null) return;

    setState(() {
      _agendamento = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String nome = _nomeController.text.trim();
    final int? duration = int.tryParse(_durationController.text.trim());
    final List<Map<String, dynamic>> metasData = _metas.map((meta) {
      final double? evalVal =
          evaluateMathExpression(meta.valorController.text);
      return {
        'id': meta.id,
        'metaVezes': int.parse(meta.metaVezesController.text),
        'valor': evalVal ??
            (double.tryParse(meta.valorController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '.')) ??
                1.0),
        'reiniciaEmQtd': int.parse(meta.reiniciaEmQtdController.text),
        'reiniciaEmTipo': meta.reiniciaEmTipo,
        'categoriaId': meta.selectedCategoryId,
      };
    }).toList();

    final bool success;
    if (widget.editingItem != null) {
      final List<String> allExistingQtdRowIds = widget
          .editingItem!
          .tarefasHabitosQtd
          .map((qtd) => qtd.id)
          .toList();
      success = await Core.tarefasHabitosController.updateTarefaHabito(
        id: widget.editingItem!.id,
        nome: nome,
        tipo: _tipo,
        metas: metasData,
        allExistingQtdRowIds: allExistingQtdRowIds,
        agendamento: _agendamento,
        duration: duration,
      );
    } else {
      success = await Core.tarefasHabitosController.createTarefaHabito(
        nome: nome,
        tipo: _tipo,
        metas: metasData,
        agendamento: _agendamento,
        duration: duration,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao salvar.')));
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover registro'),
        content: const Text('Deseja realmente remover esta tarefa ou hábito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final List<String> allExistingQtdRowIds = widget
        .editingItem!
        .tarefasHabitosQtd
        .map((qtd) => qtd.id)
        .toList();

    final bool success = await Core.tarefasHabitosController.deleteTarefaHabito(
      widget.editingItem!.id,
      allExistingQtdRowIds,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao excluir.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.editingItem == null
                        ? 'Nova Tarefa/Hábito'
                        : 'Editar Tarefa/Hábito',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (widget.lastRoute != null) {
                      Routefly.navigate(widget.lastRoute!);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o nome.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração (em minutos, Opcional)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um valor numérico válido.';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'habito',
                  label: Text('Hábito'),
                  icon: Icon(Icons.star_outline),
                ),
                ButtonSegment<String>(
                  value: 'tarefa',
                  label: Text('Tarefa'),
                  icon: Icon(Icons.task_alt),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _tipo = newSelection.first;
                  if (_tipo == 'tarefa') {
                    for (final meta in _metas) {
                      meta.metaVezesController.text = '1';
                      meta.reiniciaEmQtdController.text = '1';
                      meta.reiniciaEmTipo = 'dias';
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Metas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._metas.asMap().entries.map((entry) {
              final int idx = entry.key;
              final MetaItem meta = entry.value;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Meta ${idx + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_metas.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  meta.dispose();
                                  _metas.removeAt(idx);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Observer(
                        builder: (context) {
                          final categorias =
                              Core.categoriasController.categoriasList;
                          final bool exists = categorias.any(
                            (cat) => cat.id == meta.selectedCategoryId,
                          );

                          final List<DropdownMenuItem<String>> dropdownItems = [
                            const DropdownMenuItem<String>(
                              child: Text('Nenhuma'),
                            ),
                            ...categorias.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: cat.cor,
                                      radius: 8,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat.nome,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ];

                          if (meta.selectedCategoryId != null && !exists) {
                            dropdownItems.add(
                              DropdownMenuItem<String>(
                                value: meta.selectedCategoryId,
                                child: const Text('Carregando categoria...'),
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: meta.selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Categoria (Opcional)',
                              border: OutlineInputBorder(),
                            ),
                            items: dropdownItems,
                            onChanged: (val) {
                              setState(() {
                                meta.selectedCategoryId = val;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_tipo == 'habito') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: meta.metaVezesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Meta (Vezes)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: meta.valorController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Valor por Vez',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  if (num.tryParse(value) == null) {
                                    return 'Inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: meta.reiniciaEmQtdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reinicia a cada',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Obrigatório';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: meta.reiniciaEmTipo,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo Período',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'dias',
                                    child: Text('Dias'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'semanas',
                                    child: Text('Semanas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'meses',
                                    child: Text('Meses'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'anos',
                                    child: Text('Anos'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      meta.reiniciaEmTipo = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          controller: meta.valorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Obrigatório';
                            }
                            if (num.tryParse(value) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _metas.add(
                    MetaItem(
                      metaVezes: '1',
                      valor: '1.0',
                      reiniciaEmQtd: '1',
                      reiniciaEmTipo: 'dias',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Outra Meta'),
            ),
            if (_tipo == 'tarefa') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectAgendamento,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _agendamento == null
                      ? 'Agendar data/hora'
                      : 'Agendado: ${_agendamento!.day}/${_agendamento!.month}/${_agendamento!.year} às ${_agendamento!.hour}:${_agendamento!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.editingItem != null)
                  ElevatedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Excluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
