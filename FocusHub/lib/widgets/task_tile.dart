import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../main.dart'; // Importamos para los colores

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Opacidad y decoración de texto cambian si la tarea está completa
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: task.isComplete ? Colors.grey.shade500 : Colors.white,
          decoration:
              task.isComplete ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: Colors.grey.shade500,
          decorationThickness: 2.0,
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: kTileColor,
        borderRadius: BorderRadius.circular(12),
        // Borde sutil
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        // --- Checkbox Personalizado ---
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: task.isComplete,
            onChanged: (value) => onToggle(),
            // Estilo del checkbox
            activeColor: kAccentColor,
            checkColor: kBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: Colors.grey.shade600, width: 2),
          ),
        ),
        // --- Título de la Tarea ---
        title: Text(
          task.taskName,
          style: textStyle,
        ),
        onTap: onToggle, // Permite marcar/desmarcar pulsando toda la fila
      ),
    );
  }
}