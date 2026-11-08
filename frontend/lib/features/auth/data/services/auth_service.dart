import 'package:dio/dio.dart';
import 'package:planit_app/core/network/dio_client.dart';

class AuthService {
  final DioClient _dioClient = DioClient();

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login', // Ajusta esta ruta según los endpoints de tu Spring Boot
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Suponiendo que el backend devuelve un JSON con el token ej: { "token": "tu_jwt_aqui" }
        final token = response.data['token'];
        return token;
      }
      return null;
    } on DioException catch (e) {
      // Aquí puedes manejar errores específicos de la petición (credenciales inválidas, servidor caído, etc.)
      throw Exception('Error en el inicio de sesión: ${e.response?.data ?? e.message}');
    }
  }
}
