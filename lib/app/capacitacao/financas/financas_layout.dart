import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/app/capacitacao/financas/widgets/seletor_mes_widget.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:ppvdigital/util.dart';
import 'package:routefly/routefly.dart';

class FinancasLayout extends StatefulWidget {
  const FinancasLayout({super.key});

  @override
  State<FinancasLayout> createState() => _FinancasLayoutState();
}

class _FinancasLayoutState extends State<FinancasLayout>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey<ExpandableFabState>();

  void _closeFab() {
    final state = _key.currentState;
    if (state != null && state.isOpen) {
      state.toggle();
    }
  }

  bool _mostrarDivisoes = false;
  DateTime _selectedMonth = DateTime.now();
  DateTime _appliedMonth = DateTime.now();
  bool _isMonthChanging = false;
  Timer? _monthChangeTimer;
  String _descricaoQuery = '';
  final TextEditingController _descricaoFilterController =
      TextEditingController();
  bool _somarAcumulado = false;
  final Set<String> _selectedContas = {};
  final Set<String> _selectedTransIds = {};
  final Set<String> _selectedCategorias = {};
  final Set<String> _selectedTipos = {};
  final Set<String> _selectedContatos = {};
  final Set<bool> _selectedConsolidadas = {};
  bool _filterOpen = false;
  late final TabController _tabController;
  final ScrollController _transacoesScrollController = ScrollController();

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
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    FinancasController.financasFuture = Core.financasController.loadDocuments(
      selectedMonth: _selectedMonth,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transacoesScrollController.dispose();
    _monthChangeTimer?.cancel();
    _descricaoFilterController.dispose();
    super.dispose();
  }

  double _calcularValorDivisao(TransacaoModel t, String activeUserId) {
    if (t.divisoes.isEmpty) return t.valor;
    final double totalPeso = t.divisoes.fold(0.0, (sum, div) => sum + div.peso);
    final userDiv = t.divisoes.where((div) {
      final contact = Core.financasController.contatosList.firstWhere(
        (c) => c.id == div.contatoResponsavel,
        orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
      );
      return contact.userId == activeUserId;
    });
    if (userDiv.isEmpty) return 0.0;
    final double userPeso = userDiv.fold(0.0, (sum, div) => sum + div.peso);
    return t.valor * (userPeso / totalPeso);
  }

  Map<String, List<TransacaoModel>> _agruparPorDia(List<TransacaoModel> list) {
    final Map<String, List<TransacaoModel>> groups = {};
    for (final t in list) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.dataCompetencia);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(t);
    }
    // Sort keys ascending
    final sortedKeys = groups.keys.toList()..sort((a, b) => a.compareTo(b));
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, groups[k]!)));
  }

  double _calcularTotalDia(List<TransacaoModel> dayTrans, String activeUserId) {
    double total = 0.0;
    for (final t in dayTrans) {
      total += _calcularImpactoTransacao(t, activeUserId, _selectedContas);
    }
    return total;
  }

  Widget _buildDayGroup({
    required BuildContext context,
    required String dateKey,
    required List<TransacaoModel> dayTrans,
    required Map<String, double> saldosDiarios,
    required String activeUser,
  }) {
    final dateParsed = DateTime.parse(dateKey);
    final formattedDate = DateFormat(
      "dd 'de' MMMM, yyyy",
      'pt_BR',
    ).format(dateParsed);

    final double saldoExibido = saldosDiarios[dateKey] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.grey.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Saldo acumulado: ${saldoExibido.toCurrency()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: saldoExibido >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        ...dayTrans.map((t) {
          final double valToDisplay = _mostrarDivisoes
              ? _calcularValorDivisao(t, activeUser)
              : t.valor;

          final Color valueColor = t.tipo == 'receita'
              ? Colors.green
              : (t.tipo == 'transferencia' ? Colors.blue : Colors.red);

          final IconData catIcon =
              _presetIcons[t.categoria?.icone] ?? Icons.monetization_on;

          return ListTile(
            onTap: () {
              Routefly.pushNavigate(
                routePaths.capacitacao.criarEditarTransacao,
                arguments: {
                  'lastRoute': Routefly.currentUri.path,
                  'transacao': t,
                },
              );
            },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _selectedTransIds.contains(t.id),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedTransIds.add(t.id);
                      } else {
                        _selectedTransIds.remove(t.id);
                      }
                    });
                  },
                ),
                CircleAvatar(
                  backgroundColor:
                      t.categoria?.cor?.withValues(alpha: 0.2) ??
                      Colors.blue.withValues(alpha: 0.2),
                  child: Icon(catIcon, color: t.categoria?.cor ?? Colors.blue),
                ),
              ],
            ),
            title: Text(
              t.descricao,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.tipo == 'transferencia'
                      ? 'Transf: ${t.conta?.name ?? '?'} ➔ ${t.contaDestino?.name ?? '?'}'
                      : 'Conta: ${t.conta?.name ?? 'Sem conta'}',
                ),
                if (_mostrarDivisoes)
                  Text(
                    'Sua parcela (Valor Total: ${t.valor.toCurrency()})',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (t.recorrencia != null)
                      _buildIndicatorChip(
                        context,
                        icon: Icons.repeat,
                        label: 'Recorrente',
                        color: Colors.purple,
                      ),
                    if (t.devedorContato != null)
                      _buildIndicatorChip(
                        context,
                        icon: Icons.arrow_downward,
                        label: '${t.devedorContato!.nome} deve p/ você',
                        color: Colors.teal,
                      ),
                    if (t.credorContato != null)
                      _buildIndicatorChip(
                        context,
                        icon: Icons.arrow_upward,
                        label: 'Você deve p/ ${t.credorContato!.nome}',
                        color: Colors.orange,
                      ),
                    if (_isDivididaComOutros(t, activeUser))
                      _buildIndicatorChip(
                        context,
                        icon: Icons.pie_chart_outline,
                        label: 'Dividido (${t.divisoes.length})',
                        color: Colors.blueGrey,
                      ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valToDisplay.toCurrency(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: t.consolidada
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.consolidada ? 'Efetivada' : 'Prevista',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: t.consolidada ? Colors.green : Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 1),
      ],
    );
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
      _isMonthChanging = true;
    });

    _monthChangeTimer?.cancel();
    _monthChangeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _appliedMonth = _selectedMonth;
        _isMonthChanging = false;
        FinancasController.financasFuture = Core.financasController
            .loadDocuments(selectedMonth: _appliedMonth);
      });
    });
  }

  bool _anyFilterActive() {
    return _selectedContas.isNotEmpty ||
        _selectedCategorias.isNotEmpty ||
        _selectedTipos.isNotEmpty ||
        _selectedContatos.isNotEmpty ||
        _selectedConsolidadas.isNotEmpty ||
        _mostrarDivisoes ||
        _somarAcumulado;
  }

  @override
  Widget build(BuildContext context) {
    final String activeUser = Core.loginController.currentUser?.$id ?? '';
    final isMobile = MediaQuery.of(context).size.width < 750;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanças'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Routefly.navigate(routePaths.capacitacao.path);
          },
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: (isMobile ? _anyFilterActive() : _filterOpen)
                    ? Colors.blue
                    : null,
              ),
              tooltip: 'Filtros e Opções',
              onPressed: () {
                if (isMobile) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        maxChildSize: 0.95,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) {
                          return StatefulBuilder(
                            builder: (context, setStateSheet) {
                              return _buildInlineFilterPanel(
                                context,
                                setStateSheet,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                } else {
                  setState(() {
                    _filterOpen = !_filterOpen;
                  });
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).cardColor,
        elevation: 8,
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.swap_horiz), text: 'Transações'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Contas'),
              Tab(icon: Icon(Icons.category), text: 'Categorias'),
              Tab(icon: Icon(Icons.people), text: 'Contatos'),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
        future: FinancasController.financasFuture,
        builder: (context, snapshot) {
          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Transactions Tab
              Observer(
                builder: (context) {
                  final allTrans = Core.financasController.transacoesList;
                  final isSyncing = Core.financasController.isSyncing;

                  // Filter list based on toggle
                  List<TransacaoModel> displayTransList = [];
                  if (_mostrarDivisoes) {
                    displayTransList = allTrans
                        .where((t) => _participaComOutros(t, activeUser))
                        .toList();
                  } else {
                    displayTransList = allTrans;
                  }

                  // Apply account, category, type, and contact filters
                  List<TransacaoModel> step1List = [];
                  if (_selectedContas.isEmpty) {
                    step1List = displayTransList;
                  } else {
                    step1List = displayTransList.where((t) {
                      if (t.tipo == 'transferencia') {
                        final bool origemSel =
                            t.conta != null &&
                            _selectedContas.contains(t.conta!.id);
                        final bool destinoSel =
                            t.contaDestino != null &&
                            _selectedContas.contains(t.contaDestino!.id);
                        return origemSel || destinoSel;
                      } else {
                        return t.conta != null &&
                            _selectedContas.contains(t.conta!.id);
                      }
                    }).toList();
                  }

                  List<TransacaoModel> step2List = [];
                  if (_selectedCategorias.isEmpty) {
                    step2List = step1List;
                  } else {
                    step2List = step1List.where((t) {
                      return t.categoria != null &&
                          _selectedCategorias.contains(t.categoria!.id);
                    }).toList();
                  }

                  List<TransacaoModel> step3List = [];
                  if (_selectedTipos.isEmpty) {
                    step3List = step2List;
                  } else {
                    step3List = step2List.where((t) {
                      return _selectedTipos.contains(t.tipo);
                    }).toList();
                  }

                  List<TransacaoModel> accountFilteredList = [];
                  if (_selectedContatos.isEmpty) {
                    accountFilteredList = step3List;
                  } else {
                    accountFilteredList = step3List.where((t) {
                      final bool isDevedor =
                          t.devedorContato != null &&
                          _selectedContatos.contains(t.devedorContato!.id);
                      final bool isCredor =
                          t.credorContato != null &&
                          _selectedContatos.contains(t.credorContato!.id);
                      final bool inDivisao = t.divisoes.any(
                        (div) =>
                            _selectedContatos.contains(div.contatoResponsavel),
                      );
                      return isDevedor || isCredor || inDivisao;
                    }).toList();
                  }

                  List<TransacaoModel> statusFilteredList = [];
                  if (_selectedConsolidadas.isEmpty) {
                    statusFilteredList = accountFilteredList;
                  } else {
                    statusFilteredList = accountFilteredList.where((t) {
                      return _selectedConsolidadas.contains(t.consolidada);
                    }).toList();
                  }

                  // Apply Month filter
                  final query = _descricaoQuery.trim().toLowerCase();
                  final filteredTransList = statusFilteredList
                      .where(
                        (t) =>
                            t.dataCompetencia.year == _appliedMonth.year &&
                            t.dataCompetencia.month == _appliedMonth.month &&
                            (query.isEmpty ||
                                t.descricao.toLowerCase().contains(query)),
                      )
                      .toList();

                  Widget mainContent;

                  final grouped = _agruparPorDia(filteredTransList);
                  final Map<String, double> saldosDiarios =
                      _calcularSaldosDiarios(
                        grouped,
                        accountFilteredList,
                        activeUser,
                      );

                  mainContent = Column(
                    children: [
                      SeletorMesWidget(
                        selectedMonth: _selectedMonth,
                        onMonthChanged: _onMonthChanged,
                      ),
                      if (isSyncing)
                        const LinearProgressIndicator(minHeight: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedTransIds.isEmpty
                                  ? false
                                  : (_selectedTransIds.length ==
                                            filteredTransList.length
                                        ? true
                                        : null),
                              tristate: true,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedTransIds.addAll(
                                      filteredTransList.map((t) => t.id),
                                    );
                                  } else {
                                    _selectedTransIds.clear();
                                  }
                                });
                              },
                            ),
                            const Text(
                              'Selecionar tudo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: TextField(
                                  controller: _descricaoFilterController,
                                  decoration: const InputDecoration(
                                    hintText: 'Filtrar por descrição...',
                                    prefixIcon: Icon(Icons.search, size: 18),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _descricaoQuery = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_selectedTransIds.isNotEmpty)
                              Text(
                                '${_selectedTransIds.length} selecionadas',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            if (filteredTransList.isEmpty)
                              snapshot.connectionState ==
                                          ConnectionState.waiting ||
                                      _isMonthChanging ||
                                      isSyncing
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Center(
                                      child: Text(
                                        'Nenhuma transação encontrada.',
                                      ),
                                    )
                            else
                              Scrollbar(
                                controller: _transacoesScrollController,
                                thumbVisibility: true,
                                interactive: true,
                                child: SingleChildScrollView(
                                  controller: _transacoesScrollController,
                                  padding: const EdgeInsets.only(bottom: 80.0),
                                  child: Column(
                                    children: [
                                      for (final dateKey in grouped.keys)
                                        _buildDayGroup(
                                          context: context,
                                          dateKey: dateKey,
                                          dayTrans: grouped[dateKey]!,
                                          saldosDiarios: saldosDiarios,
                                          activeUser: activeUser,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_isMonthChanging)
                              ColoredBox(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );

                  return Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            mainContent,
                            if (_selectedTransIds.isNotEmpty)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: _buildBatchActionsBar(context),
                              ),
                          ],
                        ),
                      ),
                      if (_filterOpen && !isMobile)
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            color: Theme.of(context).cardColor,
                          ),
                          child: _buildInlineFilterPanel(context),
                        ),
                    ],
                  );
                },
              ),

              // 2. Accounts Tab
              Observer(
                builder: (context) {
                  final accounts = Core.financasController.contasList;
                  if (accounts.isEmpty) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const Center(
                      child: Text('Nenhuma conta cadastrada.'),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 80.0,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final c = accounts[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Routefly.pushNavigate(
                              routePaths.capacitacao.criarEditarConta,
                              arguments: {
                                'lastRoute': Routefly.currentUri.path,
                                'conta': c,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Saldo Atual',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      c.saldoAtual.toCurrency(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // 3. Categories Tab
              Observer(
                builder: (context) {
                  final categories = Core.financasController.categoriasList;
                  if (categories.isEmpty) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const Center(
                      child: Text('Nenhuma categoria cadastrada.'),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 80.0,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final IconData icon =
                          _presetIcons[cat.icone] ?? Icons.category;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                cat.cor?.withValues(alpha: 0.3) ??
                                Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Routefly.pushNavigate(
                              routePaths
                                  .capacitacao
                                  .criarEditarCategoriaTransacao,
                              arguments: {
                                'lastRoute': Routefly.currentUri.path,
                                'categoria': cat,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      cat.cor?.withValues(alpha: 0.15) ??
                                      Colors.blue.withValues(alpha: 0.15),
                                  child: Icon(
                                    icon,
                                    color: cat.cor ?? Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // 4. Contacts Tab
              Observer(
                builder: (context) {
                  final contatos = Core.financasController.contatosList;
                  if (contatos.isEmpty) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return const Center(
                      child: Text('Nenhum contato cadastrado.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                    itemCount: contatos.length,
                    itemBuilder: (context, index) {
                      final c = contatos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              c.nome.isNotEmpty
                                  ? c.nome.substring(0, 1).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            c.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${c.email ?? 'Sem email'} • ${c.telefone ?? 'Sem telefone'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Routefly.pushNavigate(
                                routePaths.capacitacao.criarEditarContato,
                                arguments: {
                                  'lastRoute': Routefly.currentUri.path,
                                  'contato': c,
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        distance: 240,
        children: [
          FloatingActionButton.extended(
            heroTag: 'financas_transacao_fab',
            tooltip: 'Nova Transação',
            label: const Text('Transação'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              _closeFab();
              Routefly.pushNavigate(
                routePaths.capacitacao.criarEditarTransacao,
                arguments: Routefly.currentUri.path,
              );
            },
          ),
          FloatingActionButton.extended(
            heroTag: 'financas_conta_fab',
            tooltip: 'Nova Conta',
            label: const Text('Conta'),
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              _closeFab();
              Routefly.pushNavigate(
                routePaths.capacitacao.criarEditarConta,
                arguments: Routefly.currentUri.path,
              );
            },
          ),
          FloatingActionButton.extended(
            heroTag: 'financas_categoria_fab',
            tooltip: 'Nova Categoria',
            label: const Text('Categoria'),
            icon: const Icon(Icons.category),
            onPressed: () {
              _closeFab();
              Routefly.pushNavigate(
                routePaths.capacitacao.criarEditarCategoriaTransacao,
                arguments: Routefly.currentUri.path,
              );
            },
          ),
          FloatingActionButton.extended(
            heroTag: 'financas_contato_fab',
            tooltip: 'Novo Contato',
            label: const Text('Contato'),
            icon: const Icon(Icons.person_add),
            onPressed: () {
              _closeFab();
              Routefly.pushNavigate(
                routePaths.capacitacao.criarEditarContato,
                arguments: Routefly.currentUri.path,
              );
            },
          ),
        ],
      ),
    );
  }

  double _calcularImpactoTransacao(
    TransacaoModel t,
    String activeUserId,
    Set<String> filteredContasIds,
  ) {
    final double val = _mostrarDivisoes
        ? _calcularValorDivisao(t, activeUserId)
        : t.valor;

    if (t.tipo == 'receita') {
      return val;
    } else if (t.tipo == 'despesa') {
      return -val;
    } else if (t.tipo == 'transferencia') {
      if (_mostrarDivisoes) {
        return 0.0;
      }
      if (filteredContasIds.isEmpty) {
        return 0.0;
      }
      final bool origemSel =
          t.conta != null && filteredContasIds.contains(t.conta!.id);
      final bool destinoSel =
          t.contaDestino != null &&
          filteredContasIds.contains(t.contaDestino!.id);

      if (origemSel && !destinoSel) {
        return -val;
      } else if (destinoSel && !origemSel) {
        return val;
      }
    }
    return 0.0;
  }

  bool _isDivididaComOutros(TransacaoModel t, String activeUserId) {
    if (t.divisoes.isEmpty) return false;
    return t.divisoes.any((div) {
      final contact = Core.financasController.contatosList.firstWhere(
        (c) => c.id == div.contatoResponsavel,
        orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
      );
      return contact.userId != activeUserId;
    });
  }

  bool _participaComOutros(TransacaoModel t, String activeUserId) {
    if (t.divisoes.isEmpty) return false;
    bool userIn = false;
    bool otherIn = false;
    for (final div in t.divisoes) {
      final contact = Core.financasController.contatosList.firstWhere(
        (c) => c.id == div.contatoResponsavel,
        orElse: () => ContatoModel(id: '', ownerId: '', nome: ''),
      );
      if (contact.userId == activeUserId) {
        userIn = true;
      } else {
        otherIn = true;
      }
    }
    return userIn && otherIn;
  }

  double _calcularSaldoAcumuladoAnterior(
    List<TransacaoModel> allTrans,
    String activeUserId,
    Set<String> filteredContasIds,
  ) {
    final firstDayOfSelectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    double total = 0.0;
    for (final t in allTrans) {
      if (t.dataCompetencia.isBefore(firstDayOfSelectedMonth)) {
        if (filteredContasIds.isNotEmpty) {
          if (t.tipo == 'transferencia') {
            final bool origemSel =
                t.conta != null && filteredContasIds.contains(t.conta!.id);
            final bool destinoSel =
                t.contaDestino != null &&
                filteredContasIds.contains(t.contaDestino!.id);
            if (!origemSel && !destinoSel) continue;
          } else {
            if (t.conta == null || !filteredContasIds.contains(t.conta!.id)) {
              continue;
            }
          }
        }
        total += _calcularImpactoTransacao(t, activeUserId, filteredContasIds);
      }
    }
    return total;
  }

  Map<String, double> _calcularSaldosDiarios(
    Map<String, List<TransacaoModel>> grouped,
    List<TransacaoModel> allTrans,
    String activeUserId,
  ) {
    final Map<String, double> saldos = {};
    final double acumuladoAnterior = _somarAcumulado
        ? _calcularSaldoAcumuladoAnterior(
            allTrans,
            activeUserId,
            _selectedContas,
          )
        : 0.0;

    // Sort keys ascending (chronological order)
    final List<String> sortedDateKeys = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    double running = acumuladoAnterior;
    for (final dateKey in sortedDateKeys) {
      final dayTrans = grouped[dateKey]!;
      final double dayNet = _calcularTotalDia(dayTrans, activeUserId);
      running += dayNet;
      saldos[dateKey] = running;
    }

    return saldos;
  }

  Widget _buildBatchActionsBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        color: isDark ? Colors.grey[900] : Colors.blueGrey[900],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedTransIds.length} selecionadas',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildBatchActionButton(
                    tooltip: 'Efetivar (Consolidar)',
                    icon: Icons.check_circle_outline,
                    color: Colors.greenAccent,
                    onPressed: () => _executeBatchUpdate('consolidar', true),
                  ),
                  const SizedBox(width: 8),
                  _buildBatchActionButton(
                    tooltip: 'Tornar Prevista',
                    icon: Icons.pending_actions,
                    color: Colors.amberAccent,
                    onPressed: () => _executeBatchUpdate('consolidar', false),
                  ),
                  const SizedBox(width: 8),
                  _buildBatchActionButton(
                    tooltip: 'Trocar Data',
                    icon: Icons.calendar_month,
                    color: Colors.lightBlueAccent,
                    onPressed: () => _selectBatchDate(context),
                  ),
                  const SizedBox(width: 8),
                  _buildBatchActionButton(
                    tooltip: 'Trocar Conta',
                    icon: Icons.account_balance_wallet,
                    color: Colors.purpleAccent,
                    onPressed: () => _selectBatchConta(context),
                  ),
                  const SizedBox(width: 12),
                  Container(height: 24, width: 1.5, color: Colors.white24),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Limpar Seleção',
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _selectedTransIds.clear();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _executeBatchUpdate(String action, dynamic value) async {
    bool hasRecurrente = false;
    for (final id in _selectedTransIds) {
      final matches = Core.financasController.transacoesList.where(
        (trans) => trans.id == id,
      );
      if (matches.isNotEmpty) {
        final t = matches.first;
        if (t.recorrencia != null) {
          hasRecurrente = true;
          break;
        }
      }
    }

    String recurrenceOption = 'only_current';

    if (hasRecurrente) {
      final String? selectedOpt = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Atualizar recorrências'),
            content: const Text(
              'Algumas transações selecionadas possuem recorrência. Como deseja aplicar a alteração?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('only_current'),
                child: const Text('Apenas selecionadas'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop('current_and_future'),
                child: const Text('Selecionadas e futuras'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('all'),
                child: const Text('Todas as recorrências'),
              ),
            ],
          );
        },
      );
      if (selectedOpt == null) return;
      recurrenceOption = selectedOpt;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await Core.financasController.batchUpdateTransactions(
      transIds: _selectedTransIds.toList(),
      action: action,
      newValue: value,
      recurrenceOption: recurrenceOption,
    );

    if (!mounted) return;

    Navigator.of(context).pop();

    if (success) {
      setState(() {
        _selectedTransIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transações atualizadas com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar transações.')),
      );
    }
  }

  Future<void> _selectBatchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (!mounted) return;
      await _executeBatchUpdate('dataCompetencia', picked);
    }
  }

  Future<void> _selectBatchConta(BuildContext context) async {
    final accounts = Core.financasController.contasList;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma conta cadastrada.')),
      );
      return;
    }

    final String? pickedContaId = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecione a Conta'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final conta = accounts[index];
                return ListTile(
                  title: Text(conta.name),
                  subtitle: Text(
                    'Saldo: ${conta.saldoAtual.toCurrency()}',
                  ),
                  onTap: () {
                    Navigator.of(context).pop(conta.id);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (pickedContaId != null) {
      if (!mounted) return;
      await _executeBatchUpdate('conta', pickedContaId);
    }
  }

  Widget _buildInlineFilterPanel(
    BuildContext context, [
    StateSetter? setStateSheet,
  ]) {
    void update(VoidCallback fn) {
      setState(fn);
      setStateSheet?.call(fn);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Filtros e Opções',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('Ver transações que participo em divisões'),
                  value: _mostrarDivisoes,
                  onChanged: (val) {
                    update(() {
                      _mostrarDivisoes = val;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Somar saldo acumulado dos meses passados'),
                  value: _somarAcumulado,
                  onChanged: (val) {
                    update(() {
                      _somarAcumulado = val;
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Filtrar por Conta(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Observer(
                  builder: (context) {
                    final accounts = Core.financasController.contasList;
                    if (accounts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Nenhuma conta cadastrada para filtrar.'),
                      );
                    }
                    return Column(
                      children: accounts.map((account) {
                        final isChecked = _selectedContas.contains(account.id);
                        return CheckboxListTile(
                          title: Text(account.name),
                          subtitle: Text(
                            'Saldo: ${account.saldoAtual.toCurrency()}',
                          ),
                          value: isChecked,
                          onChanged: (val) {
                            update(() {
                              if (val == true) {
                                _selectedContas.add(account.id);
                              } else {
                                _selectedContas.remove(account.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Filtrar por Tipo(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Receita'),
                  value: _selectedTipos.contains('receita'),
                  onChanged: (val) {
                    update(() {
                      if (val == true) {
                        _selectedTipos.add('receita');
                      } else {
                        _selectedTipos.remove('receita');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Despesa'),
                  value: _selectedTipos.contains('despesa'),
                  onChanged: (val) {
                    update(() {
                      if (val == true) {
                        _selectedTipos.add('despesa');
                      } else {
                        _selectedTipos.remove('despesa');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Transferência'),
                  value: _selectedTipos.contains('transferencia'),
                  onChanged: (val) {
                    update(() {
                      if (val == true) {
                        _selectedTipos.add('transferencia');
                      } else {
                        _selectedTipos.remove('transferencia');
                      }
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Filtrar por Status (Consolidação)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Efetivadas (Consolidadas)'),
                  value: _selectedConsolidadas.contains(true),
                  onChanged: (val) {
                    update(() {
                      if (val == true) {
                        _selectedConsolidadas.add(true);
                      } else {
                        _selectedConsolidadas.remove(true);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Previstas (Não consolidadas)'),
                  value: _selectedConsolidadas.contains(false),
                  onChanged: (val) {
                    update(() {
                      if (val == true) {
                        _selectedConsolidadas.add(false);
                      } else {
                        _selectedConsolidadas.remove(false);
                      }
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Filtrar por Categoria(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Observer(
                  builder: (context) {
                    final categories = Core.financasController.categoriasList;
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Nenhuma categoria cadastrada.'),
                      );
                    }
                    return Column(
                      children: categories.map((cat) {
                        final isChecked = _selectedCategorias.contains(cat.id);
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              if (cat.icone != null &&
                                  _presetIcons.containsKey(cat.icone))
                                Icon(
                                  _presetIcons[cat.icone],
                                  color: cat.cor,
                                  size: 18,
                                )
                              else
                                Icon(Icons.category, color: cat.cor, size: 18),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                          value: isChecked,
                          onChanged: (val) {
                            update(() {
                              if (val == true) {
                                _selectedCategorias.add(cat.id);
                              } else {
                                _selectedCategorias.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Filtrar por Contato(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Observer(
                  builder: (context) {
                    final contacts = Core.financasController.contatosList;
                    if (contacts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Nenhum contato cadastrado.'),
                      );
                    }
                    return Column(
                      children: contacts.map((contact) {
                        final isChecked = _selectedContatos.contains(
                          contact.id,
                        );
                        return CheckboxListTile(
                          title: Text(contact.nome),
                          value: isChecked,
                          onChanged: (val) {
                            update(() {
                              if (val == true) {
                                _selectedContatos.add(contact.id);
                              } else {
                                _selectedContatos.remove(contact.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () {
                update(() {
                  _selectedContas.clear();
                  _selectedCategorias.clear();
                  _selectedTipos.clear();
                  _selectedContatos.clear();
                  _selectedConsolidadas.clear();
                  _mostrarDivisoes = false;
                  _somarAcumulado = false;
                  _descricaoQuery = '';
                  _descricaoFilterController.clear();
                });
              },
              child: const Text('Limpar Filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
        ],
      ),
    );
  }
}
