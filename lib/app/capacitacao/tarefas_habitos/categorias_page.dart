import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ppvdigital/core.dart';
import 'package:ppvdigital/models/categorias_tarefas_habitos_model.dart';
import 'package:ppvdigital/routes.g.dart';
import 'package:routefly/routefly.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  Future<void>? _categoriasFuture;

  @override
  void initState() {
    super.initState();
    _categoriasFuture = Core.categoriasController.loadDocuments();
  }

  void _showDeleteDialog(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Categoria'),
          content: const Text(
            'Deseja realmente remover esta categoria? Isto pode afetar tarefas e hábitos associados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success =
                    await Core.categoriasController.deleteCategory(categoryId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Categoria removida com sucesso!')),
                  );
                }
              },
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _categoriasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Observer(
            builder: (context) {
              final categorias = Core.categoriasController.categoriasList;

              if (categorias.isEmpty) {
                return const Center(
                  child: Text('Nenhuma categoria cadastrada.'),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final crossAxisCount = isWide ? 3 : 1;

                  if (isWide) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3,
                      ),
                      itemCount: categorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(context, categorias[index]);
                      },
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(context, categorias[index]);
                      },
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoriasTarefasHabitosModel category,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.cor,
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            category.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: category.pai != null
              ? Text('Subcategoria de: ${category.pai}')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () {
                  Routefly.pushNavigate(
                    routePaths.capacitacao.criarEditarCategoria,
                    arguments: {
                      'lastRoute': Routefly.currentUri.path,
                      'category': category,
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, category.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
