import 'package:dio/dio.dart';
import 'env.dart';
import 'token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage storage;

  DioClient(this.storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opt, handler) async {
          final t = await storage.load();
          if (t != null && t.isNotEmpty) {
            opt.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(opt);
        },
        onError: (error, handler) {
          // Log errors for debugging
          print('DioError: ${error.message}');
          print('URL: ${error.requestOptions.uri}');
          handler.next(error);
        },
      ),
    );
  }

  // Helper methods that add /api/v1 prefix
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get('/api/v1$path', queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post('/api/v1$path', data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put('/api/v1$path', data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete('/api/v1$path');
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return dio.patch('/api/v1$path', data: data);
  }
}
