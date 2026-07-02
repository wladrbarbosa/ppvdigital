import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:ppvdigital/app/capacitacao/financas/financas_controller.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/transacao_model.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class FinancasLayout extends StatefulWidget {
  const FinancasLayout({super.key});

  @override
  State<FinancasLayout> createState() => _FinancasLayoutState();
}

class _FinancasLayoutState extends State<FinancasLayout>
    with SingleTickerProviderStateMixin {
  bool _mostrarDivisoes = false;
  DateTime _selectedMonth = DateTime.now();
  bool _somarAcumulado = false;
  final Set<String> _selectedContas = {};
  final Set<String> _selectedTransIds = {};
  bool _filterOpen = false;
  late final TabController _tabController;

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
    FinancasController.financasFuture =
        Core.financasController.loadDocuments(selectedMonth: _selectedMonth);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final String activeUser = Core.loginController.currentUser?.$id ?? '';

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
                color: _filterOpen ? Colors.blue : null,
              ),
              tooltip: 'Filtros e Opções',
              onPressed: () {
                setState(() {
                  _filterOpen = !_filterOpen;
                });
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
                // 1. Transactions Tab
                Observer(
                  builder: (context) {
                    final allTrans = Core.financasController.transacoesList;
                    final splitTrans = Core.financasController.divisoesList;

                    // Filter list based on toggle
                    List<TransacaoModel> displayTransList = [];
                    if (_mostrarDivisoes) {
                      // Fetch the transactions where the user participates in divisions
                      for (final div in splitTrans) {
                        final matched = allTrans.where(
                          (t) => t.id == div.transacaoId,
                        );
                        if (matched.isNotEmpty) {
                          displayTransList.add(matched.first);
                        }
                      }
                    } else {
                      displayTransList = allTrans;
                    }

                    // Apply account filter
                    List<TransacaoModel> accountFilteredList = [];
                    if (_selectedContas.isEmpty) {
                      accountFilteredList = displayTransList;
                    } else {
                      accountFilteredList = displayTransList.where((t) {
                        if (t.tipo == 'transferencia') {
                          final bool origemSel = t.conta != null &&
                              _selectedContas.contains(t.conta!.id);
                          final bool destinoSel = t.contaDestino != null &&
                              _selectedContas.contains(t.contaDestino!.id);
                          return origemSel || destinoSel;
                        } else {
                          return t.conta != null &&
                              _selectedContas.contains(t.conta!.id);
                        }
                      }).toList();
                    }

                    // Apply Month filter
                    final filteredTransList = accountFilteredList
                        .where(
                          (t) =>
                              t.dataCompetencia.year == _selectedMonth.year &&
                              t.dataCompetencia.month == _selectedMonth.month,
                        )
                        .toList();

                    Widget mainContent;

                    if (filteredTransList.isEmpty) {
                      mainContent = Column(
                        children: [
                          _buildMonthSelector(),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Nenhuma transação encontrada para este mês.',
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      final grouped = _agruparPorDia(filteredTransList);
                      final Map<String, double> saldosDiarios =
                          _calcularSaldosDiarios(
                            grouped,
                            accountFilteredList,
                            activeUser,
                          );

                      mainContent = Column(
                        children: [
                          _buildMonthSelector(),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80.0),
                              itemCount: grouped.length,
                              itemBuilder: (context, index) {
                                final dateKey = grouped.keys.elementAt(index);
                                final dayTrans = grouped[dateKey]!;
                                final dateParsed = DateTime.parse(dateKey);
                                final formattedDate = DateFormat(
                                  "dd 'de' MMMM, yyyy",
                                  'pt_BR',
                                ).format(dateParsed);

                                final double saldoExibido =
                                    saldosDiarios[dateKey] ?? 0.0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      color: Colors.grey.withOpacity(0.1),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'Saldo acumulado: R\$ ${saldoExibido.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: saldoExibido >= 0
                                                  ? Colors.green
                                                  : Colors.red,
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
                                          : (t.tipo == 'transferencia'
                                                ? Colors.blue
                                                : Colors.red);

                                      final IconData catIcon =
                                          _presetIcons[t.categoria?.icone] ??
                                          Icons.monetization_on;

                                      return ListTile(
                                        onTap: () {
                                          Routefly.pushNavigate(
                                            routePaths
                                                .capacitacao
                                                .criarEditarTransacao,
                                            arguments: {
                                              'lastRoute':
                                                  Routefly.currentUri.path,
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
                                                  t.categoria?.cor?.withOpacity(
                                                    0.2,
                                                  ) ??
                                                  Colors.blue.withOpacity(0.2),
                                              child: Icon(
                                                catIcon,
                                                color:
                                                    t.categoria?.cor ?? Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          t.descricao,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.tipo == 'transferencia'
                                                  ? 'Transf: ${t.conta?.name ?? '?'} ➔ ${t.contaDestino?.name ?? '?'}'
                                                  : 'Conta: ${t.conta?.name ?? 'Sem conta'}',
                                            ),
                                            if (_mostrarDivisoes)
                                              Text(
                                                'Sua parcela (Valor Total: R\$ ${t.valor.toStringAsFixed(2)})',
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
                                                if (t.divisoes.isNotEmpty)
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'R\$ ${valToDisplay.toStringAsFixed(2)}',
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
                                                    ? Colors.green.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.amber.withOpacity(
                                                        0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                t.consolidada
                                                    ? 'Efetivada'
                                                    : 'Prevista',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: t.consolidada
                                                      ? Colors.green
                                                      : Colors.amber[800],
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
                              },
                            ),
                          ),
                        ],
                      );
                    }

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
                        if (_filterOpen)
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Saldo Atual',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'R\$ ${c.saldoAtual.toStringAsFixed(2)}',
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
                                  cat.cor?.withOpacity(0.3) ??
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
                                        cat.cor?.withOpacity(0.15) ??
                                        Colors.blue.withOpacity(0.15),
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
                      return const Center(
                        child: Text('Nenhum contato cadastrado.'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        80.0,
                      ),
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
                              ).colorScheme.primary.withOpacity(0.1),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
          distance: 240,
          children: [
            FloatingActionButton.extended(
              heroTag: 'financas_transacao_fab',
              tooltip: 'Nova Transação',
              label: const Text('Transação'),
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
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
          t.contaDestino != null && filteredContasIds.contains(t.contaDestino!.id);

      if (origemSel && !destinoSel) {
        return -val;
      } else if (destinoSel && !origemSel) {
        return val;
      }
    }
    return 0.0;
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth);
    final capitalized = monthName[0].toUpperCase() + monthName.substring(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                        1,
                      );
                      FinancasController.financasFuture =
                          Core.financasController.loadDocuments(
                        selectedMonth: _selectedMonth,
                      );
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Mês atual',
                  icon: const Icon(Icons.today, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime.now();
                      FinancasController.financasFuture =
                          Core.financasController.loadDocuments(
                        selectedMonth: _selectedMonth,
                      );
                    });
                  },
                ),
              ],
            ),
            InkWell(
              onTap: () => _mostrarSeletorMesAno(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    Text(
                      capitalized,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                    1,
                  );
                  FinancasController.financasFuture =
                      Core.financasController.loadDocuments(
                    selectedMonth: _selectedMonth,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSeletorMesAno(BuildContext context) {
    int tempYear = _selectedMonth.year;
    final List<String> meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setDialogState(() {
                        tempYear--;
                      });
                    },
                  ),
                  Text(
                    tempYear.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setDialogState(() {
                        tempYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 200,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthIndex = index + 1;
                    final isSelected =
                        _selectedMonth.year == tempYear &&
                        _selectedMonth.month == monthIndex;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(tempYear, monthIndex, 1);
                          FinancasController.financasFuture =
                              Core.financasController.loadDocuments(
                            selectedMonth: _selectedMonth,
                          );
                        });
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          meses[index],
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calcularSaldoAcumuladoAnterior(
    List<TransacaoModel> allTrans,
    String activeUserId,
    Set<String> filteredContasIds,
  ) {
    final firstDayOfSelectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    double total = 0.0;
    for (final t in allTrans) {
      if (t.dataCompetencia.isBefore(firstDayOfSelectedMonth)) {
        if (filteredContasIds.isNotEmpty) {
          if (t.tipo == 'transferencia') {
            final bool origemSel =
                t.conta != null && filteredContasIds.contains(t.conta!.id);
            final bool destinoSel = t.contaDestino != null &&
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTransIds.length} selecionadas',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Efetivar (Consolidar)',
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  onPressed: () => _executeBatchUpdate('consolidar', true),
                ),
                IconButton(
                  tooltip: 'Tornar Prevista (Desconsolidar)',
                  icon: const Icon(Icons.pending_actions, color: Colors.white),
                  onPressed: () => _executeBatchUpdate('consolidar', false),
                ),
                IconButton(
                  tooltip: 'Trocar Data',
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  onPressed: () => _selectBatchDate(context),
                ),
                IconButton(
                  tooltip: 'Trocar Conta',
                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  onPressed: () => _selectBatchConta(context),
                ),
                const SizedBox(width: 8),
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
    );
  }

  Future<void> _executeBatchUpdate(String action, dynamic value) async {
    bool hasRecurrente = false;
    for (final id in _selectedTransIds) {
      final matches = Core.financasController.transacoesList.where((trans) => trans.id == id);
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
                onPressed: () => Navigator.of(context).pop('current_and_future'),
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
                  subtitle: Text('Saldo: R\$ ${conta.saldoAtual.toStringAsFixed(2)}'),
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

  Widget _buildInlineFilterPanel(BuildContext context) {
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
                    setState(() {
                      _mostrarDivisoes = val;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Somar saldo acumulado dos meses passados'),
                  value: _somarAcumulado,
                  onChanged: (val) {
                    setState(() {
                      _somarAcumulado = val;
                    });
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          subtitle: Text('Saldo: R\$ ${account.saldoAtual.toStringAsFixed(2)}'),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
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
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedContas.clear();
                  _mostrarDivisoes = false;
                  _somarAcumulado = false;
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
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
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
              color: isDark ? color.withOpacity(0.9) : color,
            ),
          ),
        ],
      ),
    );
  }
}
