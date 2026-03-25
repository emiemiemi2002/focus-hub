class Task {
  // Atributos___________________________________
  final String taskId;
  final String taskName;
  bool isComplete;
  final String userId;
  // Opcional: 'createdAt' para futuras mejoras
  // final int? createdAt;

  // Constructor________________________________
  Task({
    required this.taskId,
    required this.taskName,
    this.isComplete = false,
    required this.userId,
    // this.createdAt,
  });

  // Factory constructor para crear una Task desde un mapa JSON (ej. respuesta de DynamoDB)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      // DynamoDB a veces devuelve booleanos como números o strings, esto es más seguro:
      isComplete: json['isComplete'] == true || json['isComplete'] == 'true',
      userId: json['userId'] as String,
      // createdAt: json['createdAt'] as int?,
    );
  }

  // Método para convertir una Task a un mapa JSON (ej. para enviarla a la API)
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'isComplete': isComplete,
      'userId': userId,
      // 'createdAt': createdAt,
    };
  }

  // Método auxiliar para crear una copia de la tarea con algunos campos modificados
  // Útil para la inmutabilidad en gestores de estado, aunque aquí usaremos isComplete mutable por simplicidad.
  Task copyWith({
    String? taskId,
    String? taskName,
    bool? isComplete,
    String? userId,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      isComplete: isComplete ?? this.isComplete,
      userId: userId ?? this.userId,
    );
  }
}