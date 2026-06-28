import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/conta_model.dart';
import 'package:routefly/routefly.dart';

Route routeBuilder(BuildContext context, RouteSettings settings) {
  final args = settings.arguments;
  String? lastRoute;
  ContaModel? editingItem;

  if (args is String) {
    lastRoute = args;
  } else if (args is Map) {
    lastRoute = args['lastRoute'] as String?;
    editingItem = args['conta'] as ContaModel?;
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
          constraints: const BoxConstraints(maxWidth: 450),
          child: CriarEditarContaPage(
            editingItem: editingItem,
            lastRoute: lastRoute,
          ),
        ),
      ),
    ),
  );
}

class CriarEditarContaPage extends StatefulWidget {
  const CriarEditarContaPage({
    super.key,
    this.editingItem,
    this.lastRoute,
  });

  final ContaModel? editingItem;
  final String? lastRoute;

  @override
  State<CriarEditarContaPage> createState() => _CriarEditarContaPageState();
}

class _CriarEditarContaPageState extends State<CriarEditarContaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _saldoController = TextEditingController(text: '0.0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _nomeController.text = widget.editingItem!.name;
      _saldoController.text = widget.editingItem!.saldoAtual.toString();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String nome = _nomeController.text.trim();
    final double saldo = double.parse(_saldoController.text);

    final bool success;
    if (widget.editingItem != null) {
      success = await Core.financasController.updateConta(
        widget.editingItem!.id,
        nome,
        saldo,
      );
    } else {
      success = await Core.financasController.createConta(nome, saldo);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta salva com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar conta.')),
      );
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover conta'),
        content: const Text(
            'Deseja realmente remover esta conta? As transações vinculadas a ela não serão removidas automaticamente.'),
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

    setState(() {
      _isLoading = true;
    });

    final bool success =
        await Core.financasController.deleteConta(widget.editingItem!.id);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir conta.')),
      );
    }
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
                  widget.editingItem == null ? 'Nova Conta' : 'Editar Conta',
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
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Conta',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Insira o nome da conta.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Saldo Atual (R\$)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Insira o saldo.';
                }
                if (double.tryParse(value) == null) {
                  return 'Insira um valor numérico válido.';
                }
                return null;
              },
            ),
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
}
