import '../services/category_service.dart';
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final VoidCallback onSave;

  const TaskForm({this.task, required this.onSave});

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final CategoryService categoryService = CategoryService();
  late String title;
  late String description;
  late DateTime dueDate;
  String? selectedCategory;
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    title = widget.task?.title ?? '';
    description = widget.task?.description ?? '';
    dueDate = widget.task?.dueDate ?? DateTime.now();
    selectedCategory = widget.task?.category;
    categories = categoryService.fetchCategories();
  }

  Future<void> _selectDueDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.lightBlue,
              onPrimary: Colors.white,
              onSurface: Colors.lightBlueAccent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && selectedDate != dueDate) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(dueDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.lightBlue,
                onPrimary: Colors.white,
                onSurface: Colors.lightBlueAccent,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlue,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          dueDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  labelStyle: TextStyle(color: Colors.lightBlue),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent),
                  ),
                ),
                onSaved: (value) => title = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: Colors.lightBlue),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent),
                  ),
                ),
                onSaved: (value) => description = value!,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Category>>(
                future: categories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text(
                        'Erro ao carregar categorias: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhuma categoria disponível.');
                  } else {
                    final categoryList = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categoryList
                          .map((category) => DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedCategory = value;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: TextStyle(color: Colors.lightBlue),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDueDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Data de Vencimento',
                      hintText: "${dueDate.toLocal()}".split(' ')[0],
                      labelStyle: const TextStyle(color: Colors.lightBlue),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlue),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent),
                      ),
                    ),
                    controller: TextEditingController(
                      text: "${dueDate.toLocal()}".split(' ')[0],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final task = Task(
                        id: widget.task?.id ?? '',
                        title: title,
                        description: description,
                        dueDate: dueDate,
                        category: selectedCategory ?? '',
                      );
                      if (widget.task == null) {
                        await _firebaseService.addTask(task);
                      } else {
                        await _firebaseService.updateTask(task);
                      }
                      widget.onSave();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showTaskFormDialog(
    BuildContext context, Task? existingTask, VoidCallback onSaveCallback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewInsets.top > 0 ? 50 : 0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: MediaQuery.of(context).size.width * 0.85,
              child: TaskForm(
                task: existingTask,
                onSave: onSaveCallback,
              ),
            ),
          ),
        ),
      );
    },
  );
}
