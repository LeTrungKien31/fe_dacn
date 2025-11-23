import '../core/dio_client.dart';

class ProfileService {
  final DioClient _client;

  ProfileService(this._client);

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _client.get('/profile');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Create or update profile
  Future<Map<String, dynamic>> saveProfile({
    required String gender,
    required String dateOfBirth,
    required double heightCm,
    required double currentWeightKg,
    double? targetWeightKg,
    required String activityLevel,
    required String goal,
  }) async {
    try {
      final res = await _client.post('/profile', data: {
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'activityLevel': activityLevel,
        'goal': goal,
      });
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Get health insights (BMI, BMR, TDEE, etc.)
  Future<Map<String, dynamic>> getHealthInsights() async {
    try {
      final res = await _client.get('/profile/insights');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception('Failed to get health insights: $e');
    }
  }

  /// Check if profile exists
  Future<bool> hasProfile() async {
    try {
      await _client.get('/profile');
      return true;
    } catch (e) {
      return false;
    }
  }
}