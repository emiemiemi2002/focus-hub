import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Hub'),
      ),
      // El FAB que navega a la pantalla de añadir tarea
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      // El cuerpo principal que escucha los cambios del TaskProvider
      body: RefreshIndicator(
        // Permite "deslizar para recargar"
        onRefresh: () =>
            Provider.of<TaskProvider>(context, listen: false).loadTasks(),
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            // --- Estado de Carga ---
            if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Estado de Error ---
            if (taskProvider.error != null) {
              return _buildErrorState(context, taskProvider.error!);
            }

            // --- Estado Vacío ---
            if (taskProvider.tasks.isEmpty) {
              return _buildEmptyState(context);
            }

            // --- Estado con Datos ---
            return _buildTaskList(context, taskProvider.tasks);
          },
        ),
      ),
    );
  }

  // Widget para la lista principal de tareas
  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    // Filtramos las listas en pendientes y completadas
    final pendingTasks = tasks.where((task) => !task.isComplete).toList();
    final completedTasks = tasks.where((task) => task.isComplete).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Permite scroll
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sección de Tareas Pendientes ---
          _buildSectionHeader(context, 'PENDIENTES'),
          const SizedBox(height: 10),
          if (pendingTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  '¡Todo listo por hoy!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ...pendingTasks.map((task) => TaskTile(
                task: task,
                onToggle: () =>
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTaskStatus(task),
              )),

          // --- Sección de Tareas Completadas ---
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'COMPLETADAS'),
            const SizedBox(height: 10),
            ...completedTasks.map((task) => TaskTile(
                  task: task,
                  onToggle: () =>
                      Provider.of<TaskProvider>(context, listen: false)
                          .toggleTaskStatus(task),
                )),
          ],
          const SizedBox(height: 80), // Espacio para que el FAB no tape nada
        ],
      ),
    );
  }

  // Widget para los títulos de sección (PENDIENTES, COMPLETADAS)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  // Widget para el estado vacío (sin tareas)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona "+" para añadir tu primer tarea.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Widget para el estado de error
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error de Conexión',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No pudimos cargar tus tareas. Revisa tu conexión a internet.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Provider.of<TaskProvider>(context, listen: false).loadTasks(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}