import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:routefly/routefly.dart';

Route routeBuilder(BuildContext context, RouteSettings settings) {
  final args = settings.arguments;
  String? lastRoute;
  TransacaoModel? editingItem;

  if (args is String) {
    lastRoute = args;
  } else if (args is Map) {
    lastRoute = args['lastRoute'] as String?;
    editingItem = args['transacao'] as TransacaoModel?;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          child: CriarEditarTransacaoPage(
            editingItem: editingItem,
            lastRoute: lastRoute,
          ),
        ),
      ),
    ),
  );
}

class CriarEditarTransacaoPage extends StatefulWidget {
  const CriarEditarTransacaoPage({super.key, this.editingItem, this.lastRoute});

  final TransacaoModel? editingItem;
  final String? lastRoute;

  @override
  State<CriarEditarTransacaoPage> createState() =>
      _CriarEditarTransacaoPageState();
}

class _CriarEditarTransacaoPageState extends State<CriarEditarTransacaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController(text: '0.0');
  bool _isLoading = false;

  String _tipo = 'despesa'; // despesa, receita, transferencia
  DateTime _dataCompetencia = DateTime.now();
  String? _selectedContaId;
  String? _selectedContaDestinoId;
  String? _selectedCategoriaId;
  String? _selectedDevedorContatoId;
  String? _selectedCredorContatoId;
  bool _consolidada = false;

  // Recurrencia fields
  bool _recorrente = false;
  bool _recorrenciaIndeterminada = false;
  final _frequenciaController = TextEditingController(text: '1');
  final _totalParcelasController = TextEditingController(text: '12');
  final _parcelaInicioController = TextEditingController(text: '1');
  String _tipoRecorrencia = 'mês';

  // Divisao / Responsibles list
  final List<Map<String, dynamic>> _divisoes = [];
  String? _pagadorRecebedorId;

  final Map<String, IconData> _presetIcons = {
    'monetization_on': Icons.monetization_on,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'medical_services': Icons.medical_services,
    'school': Icons.school,
    'work': Icons.work,
    'account_balance': Icons.account_balance,
    'category': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    // Load accounts and categories just to make sure they are loaded
    Core.financasController.loadDocuments();

    if (widget.editingItem == null &&
        FinancasController.defaultDataCompetencia != null) {
      _dataCompetencia = FinancasController.defaultDataCompetencia!;
    }

    if (widget.editingItem != null) {
      final t = widget.editingItem!;
      _descricaoController.text = t.descricao;
      _valorController.text = t.valor.toString();
      _tipo = t.tipo;
      _dataCompetencia = t.dataCompetencia;
      _selectedContaId = t.conta?.id;
      _selectedContaDestinoId = t.contaDestino?.id;
      _selectedCategoriaId = t.categoria?.id;
      _selectedDevedorContatoId = t.devedorContato?.id;
      _selectedCredorContatoId = t.credorContato?.id;
      _consolidada = t.consolidada;

      // Recurrence
      if (t.recorrencia != null) {
        _recorrente = true;
        _recorrenciaIndeterminada = t.recorrencia!.totalParcelas == null;
        _frequenciaController.text = (t.recorrencia!.frequencia ?? 1)
            .toString();
        _totalParcelasController.text = (t.recorrencia!.totalParcelas ?? 12)
            .toString();
        _parcelaInicioController.text = (t.recorrencia!.parcelaInicio ?? 1)
            .toString();
        _tipoRecorrencia = t.recorrencia!.tipoRecorrencia;
      }

      // Divisions
      for (final div in t.divisoes) {
        _divisoes.add({
          'contatoResponsavel': div.contatoResponsavel,
          'peso': div.peso,
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (Core.financasController.contatosList.isEmpty) {
          await Core.financasController.loadDocuments();
        }
        _initializeUserDivisao();
      });
    }
  }

  void _initializeUserDivisao() {
    final currentUser = Core.loginController.currentUser;
    if (currentUser != null) {
      final userContato = Core.financasController.contatosList.firstWhere(
        (c) => c.userId == currentUser.$id,
        orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
      );
      if (userContato.id.isNotEmpty) {
        setState(() {
          _divisoes.add({'contatoResponsavel': userContato.id, 'peso': 1.0});
          _pagadorRecebedorId = userContato.id;
        });
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _frequenciaController.dispose();
    _totalParcelasController.dispose();
    _parcelaInicioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataCompetencia,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dataCompetencia = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dataCompetencia.hour,
          _dataCompetencia.minute,
        );
      });
    }
  }

  Future<String?> _showSaveRecurrenceDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar transação recorrente'),
        content: const Text(
          'Esta transação é recorrente. Como deseja aplicar as alterações?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('only_current'),
            child: const Text('Apenas esta'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('current_and_future'),
            child: const Text('Esta e futuras'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('all'),
            child: const Text('Todas'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? optionRecorrencia;
    if (widget.editingItem != null && widget.editingItem!.recorrencia != null) {
      optionRecorrencia = await _showSaveRecurrenceDialog(context);
      if (optionRecorrencia == null) return; // Cancelled
    }

    setState(() {
      _isLoading = true;
    });

    final String descricao = _descricaoController.text.trim();
    final double valor = double.parse(_valorController.text);

    final bool success;
    if (widget.editingItem != null) {
      success = await Core.financasController.updateTransacao(
        id: widget.editingItem!.id,
        descricao: descricao,
        valor: valor,
        tipo: _tipo,
        dataCompetencia: _dataCompetencia,
        contaId: _selectedContaId,
        contaDestinoId: _tipo == 'transferencia'
            ? _selectedContaDestinoId
            : null,
        consolidada: _consolidada,
        categoriaId: _selectedCategoriaId,
        divisao: _divisoes,
        optionRecorrencia: optionRecorrencia,
        devedorContatoId: _selectedDevedorContatoId,
        credorContatoId: _selectedCredorContatoId,
        parcelaInicio: int.tryParse(_parcelaInicioController.text) ?? 1,
        tipoRecorrencia: _recorrente ? _tipoRecorrencia : null,
        frequencia: _recorrente
            ? (int.tryParse(_frequenciaController.text) ?? 1)
            : null,
        totalParcelas: _recorrente
            ? (_recorrenciaIndeterminada
                  ? null
                  : (int.tryParse(_totalParcelasController.text) ?? 1))
            : null,
      );
    } else {
      final int freq = int.tryParse(_frequenciaController.text) ?? 1;
      final int parcelas = int.tryParse(_totalParcelasController.text) ?? 1;
      final int startParcel = int.tryParse(_parcelaInicioController.text) ?? 1;

      success = await Core.financasController.createTransacao(
        descricao: descricao,
        valor: valor,
        tipo: _tipo,
        dataCompetencia: _dataCompetencia,
        contaId: _selectedContaId,
        contaDestinoId: _tipo == 'transferencia'
            ? _selectedContaDestinoId
            : null,
        consolidada: _consolidada,
        categoriaId: _selectedCategoriaId,
        recorrente: _recorrente,
        recorrenciaIndeterminada: _recorrenciaIndeterminada,
        tipoRecorrencia: _tipoRecorrencia,
        frequencia: freq,
        totalParcelas: parcelas,
        parcelaInicio: startParcel,
        divisao: _divisoes,
        devedorContatoId: _selectedDevedorContatoId,
        credorContatoId: _selectedCredorContatoId,
        pagadorRecebedorId: _pagadorRecebedorId,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação salva com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar transação.')),
      );
    }
  }

  Future<void> _delete() async {
    final String option;
    if (widget.editingItem!.recorrencia != null) {
      // Prompt deletion choices
      final selectedOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remover transação recorrente'),
          content: const Text(
            'Esta transação faz parte de uma recorrência. Como deseja prosseguir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('only_current'),
              child: const Text('Apenas esta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('current_and_future'),
              child: const Text('Esta e futuras'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('all'),
              child: const Text('Todas as parcelas'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
      if (selectedOption == null) return;
      option = selectedOption;
    } else {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remover transação'),
          content: const Text('Deseja realmente remover esta transação?'),
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
      if (confirm != true) return;
      option = 'only_current';
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final bool success = await Core.financasController.deleteTransaction(
      transacao: widget.editingItem!,
      deleteOption: option,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação excluída com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir transação.')),
      );
    }
  }

  void _addResponsavel() {
    setState(() {
      _divisoes.add({'contatoResponsavel': '', 'peso': 1.0});
    });
  }

  void _removeResponsavel(int index) {
    setState(() {
      _divisoes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.editingItem == null
                      ? 'Nova Transação'
                      : 'Editar Transação',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Insira uma descrição.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Insira o valor.';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Insira um valor numérico.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'despesa',
                        child: Text('Despesa'),
                      ),
                      DropdownMenuItem(
                        value: 'receita',
                        child: Text('Receita'),
                      ),
                      DropdownMenuItem(
                        value: 'transferencia',
                        child: Text('Transferência'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tipo = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Data: ${_dataCompetencia.day}/${_dataCompetencia.month}/${_dataCompetencia.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      const Text('Consolidada:'),
                      Switch(
                        value: _consolidada,
                        onChanged: (val) {
                          setState(() {
                            _consolidada = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (context) {
                final accounts = Core.financasController.contasList;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedContaId,
                  decoration: InputDecoration(
                    labelText: _tipo == 'transferencia'
                        ? 'Conta de Origem'
                        : 'Conta',
                    border: const OutlineInputBorder(),
                  ),
                  items: accounts.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name} (Saldo: R\$ ${c.saldoAtual.toStringAsFixed(2)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedContaId = val;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a conta.';
                    }
                    return null;
                  },
                );
              },
            ),
            if (_tipo == 'transferencia') ...[
              const SizedBox(height: 16),
              Observer(
                builder: (context) {
                  final accounts = Core.financasController.contasList;
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedContaDestinoId,
                    decoration: const InputDecoration(
                      labelText: 'Conta de Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.name} (Saldo: R\$ ${c.saldoAtual.toStringAsFixed(2)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedContaDestinoId = val;
                      });
                    },
                    validator: (value) {
                      if (_tipo == 'transferencia' && value == null) {
                        return 'Selecione a conta de destino.';
                      }
                      return null;
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            Observer(
              builder: (context) {
                final categories = Core.financasController.categoriasList;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategoriaId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(child: Text('Nenhuma')),
                    ...categories.map((cat) {
                      final IconData icon =
                          _presetIcons[cat.icone] ?? Icons.category;
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(icon, color: cat.cor, size: 20),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoriaId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (context) {
                final contatos = Core.financasController.contatosList;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedDevedorContatoId,
                  decoration: const InputDecoration(
                    labelText: 'Devedor Contato (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(child: Text('Nenhum')),
                    ...contatos.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.nome));
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDevedorContatoId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (context) {
                final contatos = Core.financasController.contatosList;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCredorContatoId,
                  decoration: const InputDecoration(
                    labelText: 'Credor Contato (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(child: Text('Nenhum')),
                    ...contatos.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.nome));
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCredorContatoId = val;
                    });
                  },
                );
              },
            ),
            if (widget.editingItem == null) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Repetir esta transação (Recorrência)'),
                value: _recorrente,
                onChanged: (val) {
                  setState(() {
                    _recorrente = val ?? false;
                  });
                },
              ),
              if (_recorrente) ...[
                const SizedBox(height: 8),
                _buildRecurrenceFields(),
              ],
            ] else if (widget.editingItem!.recorrencia != null) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recorrência',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              _buildRecurrenceFields(),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Divisão de Valores (Pesos)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addResponsavel,
                  icon: const Icon(Icons.add),
                  label: const Text('Responsável'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _divisoes.length,
              itemBuilder: (context, index) {
                final div = _divisoes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Observer(
                          builder: (context) {
                            final contatos =
                                Core.financasController.contatosList;
                            return DropdownButtonFormField<String?>(
                              initialValue:
                                  (div['contatoResponsavel'] == null ||
                                      (div['contatoResponsavel'] as String)
                                          .isEmpty)
                                  ? null
                                  : div['contatoResponsavel'] as String?,
                              decoration: const InputDecoration(
                                labelText: 'Responsável',
                                border: OutlineInputBorder(),
                              ),
                              items: contatos.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nome),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  div['contatoResponsavel'] = val ?? '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Selecione';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: div['peso'].toString(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Peso',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            div['peso'] = double.tryParse(val) ?? 1.0;
                          },
                          validator: (value) {
                            if (value == null ||
                                double.tryParse(value) == null) {
                              return 'Peso inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeResponsavel(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_divisoes.length > 1 &&
                (_tipo == 'despesa' || _tipo == 'receita')) ...[
              const SizedBox(height: 16),
              Observer(
                builder: (context) {
                  final labelText = _tipo == 'despesa'
                      ? 'Quem pagou?'
                      : 'Quem recebeu?';
                  final contatos = Core.financasController.contatosList;
                  final availableContactIds = _divisoes
                      .map((d) => d['contatoResponsavel'] as String?)
                      .where((id) => id != null && id.isNotEmpty)
                      .toSet();

                  // Make sure _pagadorRecebedorId is still in available options, otherwise reset it
                  if (_pagadorRecebedorId != null &&
                      !availableContactIds.contains(_pagadorRecebedorId)) {
                    final currentUser = Core.loginController.currentUser;
                    final userContato = contatos.firstWhere(
                      (c) => currentUser != null && c.userId == currentUser.$id,
                      orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
                    );
                    if (userContato.id.isNotEmpty &&
                        availableContactIds.contains(userContato.id)) {
                      _pagadorRecebedorId = userContato.id;
                    } else if (availableContactIds.isNotEmpty) {
                      _pagadorRecebedorId = availableContactIds.first;
                    } else {
                      _pagadorRecebedorId = null;
                    }
                  } else if (_pagadorRecebedorId == null &&
                      availableContactIds.isNotEmpty) {
                    final currentUser = Core.loginController.currentUser;
                    final userContato = contatos.firstWhere(
                      (c) => currentUser != null && c.userId == currentUser.$id,
                      orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
                    );
                    if (userContato.id.isNotEmpty &&
                        availableContactIds.contains(userContato.id)) {
                      _pagadorRecebedorId = userContato.id;
                    } else {
                      _pagadorRecebedorId = availableContactIds.first;
                    }
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _pagadorRecebedorId,
                    decoration: InputDecoration(
                      labelText: labelText,
                      border: const OutlineInputBorder(),
                    ),
                    items: availableContactIds.map((id) {
                      final contact = contatos.firstWhere(
                        (c) => c.id == id,
                        orElse: () => ContatoModel(
                          id: id!,
                          ownerId: '',
                          nome: 'Desconhecido',
                        ),
                      );
                      return DropdownMenuItem(
                        value: id,
                        child: Text(contact.nome),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _pagadorRecebedorId = val;
                      });
                    },
                    validator: (value) {
                      if (_divisoes.length > 1 &&
                          (value == null || value.isEmpty)) {
                        return 'Selecione uma opção';
                      }
                      return null;
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.editingItem != null)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _delete,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.delete, color: Colors.white),
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
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Recorrência indeterminada (Infinita)'),
          value: _recorrenciaIndeterminada,
          onChanged: (val) {
            setState(() {
              _recorrenciaIndeterminada = val;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _frequenciaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_recorrente &&
                      (value == null || int.tryParse(value) == null)) {
                    return 'Frequência inválida.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _tipoRecorrencia,
                decoration: const InputDecoration(
                  labelText: 'Período',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'dia', child: Text('Dias')),
                  DropdownMenuItem(value: 'semana', child: Text('Semanas')),
                  DropdownMenuItem(value: 'mês', child: Text('Meses')),
                  DropdownMenuItem(value: 'ano', child: Text('Anos')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _tipoRecorrencia = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (!_recorrenciaIndeterminada) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _parcelaInicioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Parcela Inicial',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_recorrente &&
                        !_recorrenciaIndeterminada &&
                        (value == null || int.tryParse(value) == null)) {
                      return 'Parcela inicial inválida.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _totalParcelasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nº Parcelas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_recorrente &&
                        !_recorrenciaIndeterminada &&
                        (value == null || int.tryParse(value) == null)) {
                      return 'Parcelas inválidas.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
