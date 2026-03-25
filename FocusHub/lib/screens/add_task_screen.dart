import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../main.dart'; // Importamos para los colores

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    // 1. Validar que el campo no esté vacío
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 2. Crear el nuevo objeto Tarea
      final newTask = Task(
        taskId: _uuid.v4(), // Generamos UUID en el cliente
        taskName: _textController.text,
        userId: 'demo_user', // Hardcodeado como en el backend
        isComplete: false,
      );

      // 3. Llamar al Provider para guardar
      await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

      // 4. Volver a la pantalla anterior si todo salió bien
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // 5. Mostrar error si falla
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Campo de Texto ---
              TextFormField(
                controller: _textController,
                autofocus: true, // El teclado aparece al abrir
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Nombre de la tarea',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: kTileColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kAccentColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // --- Botón de Guardar ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTask, // Deshabilitar si está guardando
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: kBgColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: kBgColor,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Guardar Tarea',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}