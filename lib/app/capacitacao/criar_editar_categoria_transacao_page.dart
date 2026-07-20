import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categoria_transacao_model.dart';
import 'package:routefly/routefly.dart';

Route routeBuilder(BuildContext context, RouteSettings settings) {
  final args = settings.arguments;
  String? lastRoute;
  CategoriaTransacaoModel? editingItem;

  if (args is String) {
    lastRoute = args;
  } else if (args is Map) {
    lastRoute = args['lastRoute'] as String?;
    editingItem = args['categoria'] as CategoriaTransacaoModel?;
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
          constraints: const BoxConstraints(maxWidth: 450),
          child: CriarEditarCategoriaTransacaoPage(
            editingItem: editingItem,
            lastRoute: lastRoute,
          ),
        ),
      ),
    ),
  );
}

class CriarEditarCategoriaTransacaoPage extends StatefulWidget {
  const CriarEditarCategoriaTransacaoPage({
    super.key,
    this.editingItem,
    this.lastRoute,
  });

  final CategoriaTransacaoModel? editingItem;
  final String? lastRoute;

  @override
  State<CriarEditarCategoriaTransacaoPage> createState() =>
      _CriarEditarCategoriaTransacaoPageState();
}

class _CriarEditarCategoriaTransacaoPageState
    extends State<CriarEditarCategoriaTransacaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _isLoading = false;

  Color _selectedColor = Colors.blue;
  String _selectedIcon = 'monetization_on';

  final List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.blueGrey,
  ];

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
    if (widget.editingItem != null) {
      _nomeController.text = widget.editingItem!.name;
      _selectedColor = widget.editingItem!.cor ?? Colors.blue;
      _selectedIcon = widget.editingItem!.icone ?? 'monetization_on';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String nome = _nomeController.text.trim();
    final String hexColor = _selectedColor.toHex(leadingHashSign: false);

    final bool success;
    if (widget.editingItem != null) {
      success = await Core.financasController.updateCategoria(
        widget.editingItem!.id,
        nome,
        _selectedIcon,
        hexColor,
      );
    } else {
      success = await Core.financasController.createCategoria(
        nome,
        _selectedIcon,
        hexColor,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria salva com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar categoria.')),
      );
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover categoria'),
        content: const Text(
          'Deseja realmente remover esta categoria? As transações vinculadas continuarão existindo sem categoria.',
        ),
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

    final bool success = await Core.financasController.deleteCategoria(
      widget.editingItem!.id,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída com sucesso!')),
      );
      if (widget.lastRoute != null) {
        Routefly.navigate(widget.lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir categoria.')),
      );
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
                        ? 'Nova Categoria'
                        : 'Editar Categoria',
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
                labelText: 'Nome da Categoria',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Insira o nome da categoria.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha uma Cor',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((color) {
                final bool isSelected =
                    _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolha um Ícone',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _presetIcons.entries.map((entry) {
                final String iconName = entry.key;
                final IconData iconData = entry.value;
                final bool isSelected = _selectedIcon == iconName;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? _selectedColor : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
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
