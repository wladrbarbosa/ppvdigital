import 'package:flutter/material.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:routefly/routefly.dart';

class CriarEditarCategoriaPage extends StatefulWidget {
  const CriarEditarCategoriaPage({super.key});

  @override
  State<CriarEditarCategoriaPage> createState() =>
      _CriarEditarCategoriaPageState();
}

class _CriarEditarCategoriaPageState extends State<CriarEditarCategoriaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  Color _selectedColor = const Color(0xFF4FC3F7); // Default light blue
  String? _parentCategoryId;

  final List<Color> _presetColors = const [
    Color(0xFFE57373), // Red
    Color(0xFFF06292), // Pink
    Color(0xFFBA68C8), // Purple
    Color(0xFF7986CB), // Indigo
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF4DB6AC), // Teal
    Color(0xFF81C784), // Green
    Color(0xFFFFB74D), // Orange
    Color(0xFF90A4AE), // Grey-blue
  ];

  CategoriasTarefasHabitosModel? _editingCategory;
  String? _lastRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _lastRoute = args;
    } else if (args is Map) {
      _lastRoute = args['lastRoute'] as String?;
      _editingCategory = args['category'] as CategoriasTarefasHabitosModel?;
      if (_editingCategory != null) {
        _nomeController.text = _editingCategory!.nome;
        _selectedColor = _editingCategory!.cor;
        _parentCategoryId = _editingCategory!.pai;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final String nome = _nomeController.text.trim();

    final bool success;
    if (_editingCategory != null) {
      success = await Core.categoriasController.updateCategory(
        id: _editingCategory!.id,
        nome: nome,
        cor: _selectedColor,
        pai: _parentCategoryId,
      );
    } else {
      success = await Core.categoriasController.createCategory(
        nome: nome,
        cor: _selectedColor,
        pai: _parentCategoryId,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria salva com sucesso!')),
      );
      if (_lastRoute != null) {
        Routefly.navigate(_lastRoute!);
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar categoria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // List available parent categories, excluding current one if editing
    final otherCategories = Core.categoriasController.categoriasList
        .where(
          (el) => _editingCategory == null || el.id != _editingCategory!.id,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editingCategory == null ? 'Criar Categoria' : 'Editar Categoria',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_lastRoute != null) {
              Routefly.navigate(_lastRoute!);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o nome.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Escolha uma Cor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _presetColors.map((color) {
                    final isSelected =
                        _selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(width: 3) : null,
                          boxShadow: [
                            if (isSelected)
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _parentCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoria Pai (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      child: Text(
                        'Nenhuma (Categoria Principal)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...otherCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.nome, // Storing name or ID
                        child: Text(cat.nome, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _parentCategoryId = val;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Salvar Categoria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
