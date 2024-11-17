import 'package:flutter/material.dart';
import '../screens/task_form.dart';
import '../services/firebase_service.dart';
import '../services/category_service.dart';
import '../models/task.dart';
import '../models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();
  final CategoryService categoryService = CategoryService();
  late Future<List<Task>> tasks;
  late Future<List<Category>> categories;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchTasks();
    fetchCategories();
  }

  void fetchTasks() {
    setState(() {
      tasks = firebaseService.fetchTasks();
    });
  }

  void fetchCategories() {
    setState(() {
      categories = categoryService.fetchCategories();
    });
  }

  void _openTaskForm({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return TaskForm(
          task: task,
          onSave: fetchTasks,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'To-Do List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue,
        actions: [
          FutureBuilder<List<Category>>(
            future: categories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox.shrink();
              } else {
                final categoryList = snapshot.data!;
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onSelected: (category) {
                    setState(() {
                      selectedCategory = category == "Todas" ? null : category;
                    });
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> menuItems = [
                      const PopupMenuItem(
                        value: "Todas",
                        child: Text("Todas"),
                      ),
                    ];
                    menuItems.addAll(categoryList.map((category) {
                      return PopupMenuItem(
                        value: category.name,
                        child: Text(category.name),
                      );
                    }).toList());
                    return menuItems;
                  },
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar tarefas.',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma tarefa disponível.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          } else {
            final filteredTasks = snapshot.data!.where((task) {
              return selectedCategory == null ||
                  task.category == selectedCategory;
            }).toList();
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final isDueSoon =
                    task.dueDate.difference(DateTime.now()).inDays <= 1;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDueSoon ? Colors.red : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          task.description.isNotEmpty
                              ? task.description
                              : 'Sem descrição',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.lightBlue),
                            const SizedBox(width: 4),
                            Text(
                              "${task.dueDate.toLocal()}".split(' ')[0],
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.lightBlue),
                            const SizedBox(width: 4),
                            Text(
                              "${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await firebaseService.deleteTask(task.id);
                        fetchTasks();
                      },
                    ),
                    onTap: () => _openTaskForm(task: task),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}