import 'package:dio/dio.dart';
import 'package:planit_app/core/network/dio_client.dart';

class AuthService {
  final DioClient _dioClient = DioClient();

  Future<String?> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data.toString();
        // El backend responde en texto plano con prefijo "Token JWT: "
        final token = rawData.startsWith('Token JWT: ')
            ? rawData.replaceFirst('Token JWT: ', '').trim()
            : rawData.trim();

        return token.isNotEmpty ? token : null;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(
        'Error en el inicio de sesión: ${e.response?.data ?? e.message ?? 'sin detalle'}',
      );
    }
  }
}