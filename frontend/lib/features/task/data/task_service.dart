import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:planit_app/core/network/dio_client.dart';

class TaskItem {
  final int? id;
  final String title;
  final String? description;
  final String taskType;
  final DateTime startDate;
  final DateTime dueDate;
  final String reminderFrequency;
  final bool reminderActive;
  final bool completed;
  final int subjectId;

  TaskItem({
    this.id,
    required this.title,
    this.description,
    this.taskType = 'tarea',
    required this.startDate,
    required this.dueDate,
    this.reminderFrequency = 'progresivo',
    this.reminderActive = true,
    this.completed = false,
    required this.subjectId,
  });

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    String? taskType,
    DateTime? startDate,
    DateTime? dueDate,
    String? reminderFrequency,
    bool? reminderActive,
    bool? completed,
    int? subjectId,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      reminderActive: reminderActive ?? this.reminderActive,
      completed: completed ?? this.completed,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      taskType: json['taskType'] as String? ?? 'tarea',
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      reminderFrequency: json['reminderFrequency'] as String? ?? 'progresivo',
      reminderActive: json['reminderActive'] as bool? ?? true,
      completed: json['completed'] as bool? ?? false,
      subjectId: json['subjectId'] as int? ?? 1,
    );
  }

  String _toIsoLocal(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'taskType': taskType,
      'startDate': _toIsoLocal(startDate),
      'dueDate': _toIsoLocal(dueDate),
      'reminderFrequency': reminderFrequency,
      'reminderActive': reminderActive,
      'completed': completed,
      'subjectId': subjectId,
    };
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();
}

class TaskService {
  final Dio _dio = DioClient().dio;

  static const String _endpoint = '/tasks';

  Future<List<TaskItem>> getTasks() async {
    final response = await _dio.get(_endpoint);
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<TaskItem> createTask(TaskItem task) async {
    final response = await _dio.post(_endpoint, data: task.toCreateJson());
    debugPrint('Tarea creada en backend: ${response.data}');
    return TaskItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    if (task.id == null) {
      throw ArgumentError('No se puede actualizar una tarea sin id');
    }
    final response = await _dio.put(
      '$_endpoint/${task.id}',
      data: task.toUpdateJson(),
    );
    debugPrint('Tarea actualizada en backend: ${response.data}');
    return TaskItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete(
        '$_endpoint/$id',
        options: Options(responseType: ResponseType.plain),
      );
      debugPrint('Tarea eliminada en backend: id=$id');
    } on DioException catch (e) {
      print('Error al eliminar tarea: ${e.response?.statusCode} - ${e.response?.data}');
      rethrow;
    }
  }
}