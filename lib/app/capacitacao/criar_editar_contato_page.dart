import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/contato_model.dart';
import 'package:routefly/routefly.dart';

Route routeBuilder(BuildContext context, RouteSettings settings) {
  final args = settings.arguments;
  String? lastRoute;
  ContatoModel? editingItem;

  if (args is String) {
    lastRoute = args;
  } else if (args is Map) {
    lastRoute = args['lastRoute'] as String?;
    editingItem = args['contato'] as ContatoModel?;
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
          child: CriarEditarContatoPage(
            editingItem: editingItem,
            lastRoute: lastRoute,
          ),
        ),
      ),
    ),
  );
}

class CriarEditarContatoPage extends StatefulWidget {
  const CriarEditarContatoPage({super.key, this.editingItem, this.lastRoute});

  final ContatoModel? editingItem;
  final String? lastRoute;

  @override
  State<CriarEditarContatoPage> createState() => _CriarEditarContatoPageState();
}

class _CriarEditarContatoPageState extends State<CriarEditarContatoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      _nomeController.text = widget.editingItem!.nome;
      _telefoneController.text = widget.editingItem!.telefone ?? '';
      _emailController.text = widget.editingItem!.email ?? '';
      _userIdController.text = widget.editingItem!.userId ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String nome = _nomeController.text.trim();
    final String? telefone = _telefoneController.text.trim().isEmpty
        ? null
        : _telefoneController.text.trim();
    final String? email = _emailController.text.trim().isEmpty
        ? null
        : _emailController.text.trim();
    final String? userId = _userIdController.text.trim().isEmpty
        ? null
        : _userIdController.text.trim();

    final bool success;
    if (widget.editingItem != null) {
      success = await Core.financasController.updateContato(
        id: widget.editingItem!.id,
        nome: nome,
        telefone: telefone,
        email: email,
        userId: userId,
      );
    } else {
      success = await Core.financasController.createContato(
        nome: nome,
        telefone: telefone,
        email: email,
        userId: userId,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato salvo com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao salvar contato.')));
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover contato'),
        content: const Text('Deseja realmente remover este contato?'),
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

    final bool success = await Core.financasController.deleteContato(
      widget.editingItem!.id,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato excluído com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao excluir contato.')));
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
                  widget.editingItem == null
                      ? 'Novo Contato'
                      : 'Editar Contato',
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
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Insira o nome.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'ID do Usuário (Opcional)',
                border: OutlineInputBorder(),
              ),
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
