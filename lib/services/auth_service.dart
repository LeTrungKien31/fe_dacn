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
    try {
      // Backend expects 'fullName' (camelCase)
      final r = await _client.dio.post(
        '/api/v1/auth/register',
        data: {'fullName': fullname, 'email': email, 'password': password},
      );

      // Backend returns { "token": "..." }
      final token = (r.data is Map) ? r.data['token'] as String? : null;
      if (token != null && token.isNotEmpty) {
        await _storage.save(token);
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      // Clear old token
      await _storage.clear();

      final r = await _client.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // Backend returns { "token": "..." }
      final token = (r.data is Map) ? r.data['token'] as String? : null;
      if (token == null || token.isEmpty) {
        throw Exception('No token received from server');
      }
      await _storage.save(token);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final r = await _client.get('/user/me');
      return Map<String, dynamic>.from(r.data);
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  Future<void> logout() => _storage.clear();
}
