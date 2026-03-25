import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  // Instancia del servicio API
  final ApiService _apiService = ApiService();

  // Estado interno
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  // Getters para que la UI pueda leer el estado (pero no modificarlo directamente)
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar tareas desde la API
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notificar a la UI para que muestre el spinner de carga

    try {
      _tasks = await _apiService.fetchTasks();
    } catch (e) {
      _error = e.toString();
      _tasks = []; // Limpiar lista en caso de error grave
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica a la UI que la carga terminó (con éxito o error)
    }
  }

  // Añadir una nueva tarea
  Future<void> addTask(Task newTask) async {
    // Opcional: Podríamos añadirla localmente primero para una UI "instantánea" (optimista),
    // pero como debemos esperar a que AWS genere el ID o confirme, mejor mostramos carga.
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.createTask(newTask);
      // Recargamos toda la lista para asegurar sincronización perfecta con el backend
      // (especialmente si el backend añade campos extra como timestamps)
      await loadTasks();
    } catch (e) {
      _error = "Error al crear tarea: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      rethrow; // Relanzamos para que la pantalla de 'AddTask' pueda mostrar un SnackBar si quiere
    }
  }

  // Cambiar el estado de una tarea (Completada/Pendiente)
  Future<void> toggleTaskStatus(Task task) async {
    final oldStatus = task.isComplete;
    final newStatus = !oldStatus;

    // 1. Actualización Optimista: Actualizamos la UI *inmediatamente*
    // Buscamos la tarea en la lista local y cambiamos su estado
    final index = _tasks.indexWhere((t) => t.taskId == task.taskId);
    if (index != -1) {
      _tasks[index].isComplete = newStatus;
      notifyListeners(); // ¡La UI se actualiza al instante!
    }

    // 2. Llamada a la API en segundo plano
    try {
      await _apiService.updateTaskStatus(task.taskId, newStatus);
      // Si todo va bien, no necesitamos hacer nada más, la UI ya está correcta.
    } catch (e) {
      // 3. Rollback (Reversión) si la API falla
      // Si hubo error, revertimos el cambio local para que coincida con el servidor
      if (index != -1) {
        _tasks[index].isComplete = oldStatus;
        notifyListeners(); // Notificamos el cambio de vuelta
        // Aquí podrías usar un servicio de SnackBar global para avisar al usuario del error
        print("Error al actualizar estado, revirtiendo cambios: $e");
      }
    }
  }
}