import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class ApiService {
  // URL DE API GATEWAY
  static const String _baseUrl = 'https://owwep54hf3.execute-api.us-east-1.amazonaws.com/dev';

  // Headers estándar para las peticiones JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // GET /tasks: Obtener todas las tareas
  Future<List<Task>> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tasks'));

      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON (que es una lista de objetos)
        final List<dynamic> body = jsonDecode(response.body);
        // Convertir cada objeto JSON en una instancia de Task
        return body.map((dynamic item) => Task.fromJson(item)).toList();
      } else {
        throw Exception('Fallo al cargar tareas: ${response.statusCode}');
      }
    } catch (e) {
      // Manejo básico de errores (ej. sin internet)
      print('Error en fetchTasks: $e');
      rethrow; // Relanzar para que el Provider pueda manejarlo (mostrar error en UI)
    }
  }

  // POST /tasks: Crear una nueva tarea
  Future<void> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: _headers,
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Fallo al crear tarea: ${response.body}');
      }
    } catch (e) {
      print('Error en createTask: $e');
      rethrow;
    }
  }

  // PUT /tasks/{taskId}: Actualizar el estado de una tarea
  Future<void> updateTaskStatus(String taskId, bool isComplete) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: _headers,
        body: jsonEncode({'isComplete': isComplete}),
      );

      if (response.statusCode != 200) {
        throw Exception('Fallo al actualizar tarea: ${response.body}');
      }
    } catch (e) {
      print('Error en updateTaskStatus: $e');
      rethrow;
    }
  }
}