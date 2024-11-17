import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService categoryService = CategoryService();
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    categories = categoryService.fetchCategories();
  }

  void _refreshCategories() {
    setState(() {
      categories = categoryService.fetchCategories();
    });
  }

  void _showCategoryModal({Category? category}) {
    final _formKey = GlobalKey<FormState>();
    String name = category?.name ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category == null ? 'Nova Categoria' : 'Editar Categoria',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    labelStyle: TextStyle(
                        color:
                            Colors.lightBlueAccent), // Cor do texto do rótulo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.lightBlueAccent, // Azul claro para borda
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Colors.lightBlueAccent, // Azul claro quando focado
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'O nome não pode ser vazio' : null,
                  onSaved: (value) => name = value!,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        final newCategory = Category(
                          id: category?.id ?? '',
                          name: name,
                        );
                        if (category == null) {
                          await categoryService.addCategory(newCategory);
                        } else {
                          await categoryService.updateCategory(newCategory);
                        }
                        _refreshCategories();
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.lightBlueAccent, // Azul claro para o botão
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(color: Colors.white), // Texto em branco
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerenciar Categorias',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar categorias.',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma categoria cadastrada.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await categoryService.deleteCategory(category.id);
                        _refreshCategories();
                      },
                    ),
                    onTap: () => _showCategoryModal(category: category),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryModal(),
        backgroundColor: Colors.lightBlueAccent, // Azul claro para o FAB
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
