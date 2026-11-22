import 'package:dio/dio.dart';
import 'package:planit_app/core/network/dio_client.dart';

class SubjectItem {
  final int? id;
  final String name;
  final String color;

  SubjectItem({
    this.id,
    required this.name,
    this.color = '#3B82F6',
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }
}

class SubjectService {
  final Dio _dio = DioClient().dio;

  Future<List<SubjectItem>> getSubjects() async {
    final response = await _dio.get('/subjects');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SubjectItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectItem> createSubject({
    required String name,
    String color = '#3B82F6',
  }) async {
    final response = await _dio.post(
      '/subjects',
      data: {
        'name': name,
        'color': color,
      },
    );
    return SubjectItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSubject(int id) async {
    try {
      await _dio.delete(
        '/api/subjects/$id',
        options: Options(responseType: ResponseType.plain),
      );
      print('Asignatura eliminada en backend: id=$id');
    } on DioException catch (e) {
      print('Error al eliminar asignatura: ${e.response?.statusCode} - ${e.response?.data}');
      rethrow;
    }
  }
}