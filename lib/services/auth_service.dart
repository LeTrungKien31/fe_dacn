import '../core/dio_client.dart';
import '../core/token_storage.dart';

class AuthService {
  final DioClient _client;
  final TokenStorage _storage;

  AuthService(this._client, this._storage);

  Future<void> register({
    required String fullname,
    required String email,
    required String password,
  }) async {
    // Use 'fullName' (camelCase) to match backend DTO
    final r = await _client.dio.post(
      '/api/v1/auth/register',
      data: {'fullName': fullname, 'email': email, 'password': password},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('Đăng ký lỗi ${r.statusCode}: ${r.data}');
    }
    // Optionally save token from registration
    final token = (r.data is Map) ? r.data['token'] as String? : null;
    if (token != null && token.isNotEmpty) {
      await _storage.save(token);
    }
  }

  Future<void> login({required String email, required String password}) async {
    // Clear old token
    await _storage.clear();

    final r = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    if (r.statusCode != 200) {
      throw Exception('Đăng nhập lỗi ${r.statusCode}: ${r.data}');
    }
    // FIX: Backend returns "token", not "accessToken"
    final token = (r.data is Map) ? r.data['token'] as String? : null;
    if (token == null || token.isEmpty) {
      throw Exception('Không nhận được token');
    }
    await _storage.save(token);
  }

  Future<Map<String, dynamic>> me() async {
    final r = await _client.get('/user/me');
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> logout() => _storage.clear();
}
