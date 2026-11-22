import 'package:dio/dio.dart';
import 'package:planit_app/core/constants/api_constants.dart';
import 'package:planit_app/core/storage/token_storage.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth/login')) {
            final token = await TokenStorage.getToken();
            print('URL: ${options.uri}');
            print('Token leído: ${token != null && token.isNotEmpty ? "SÍ (${token.length} chars)" : "NO / VACÍO"}');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
