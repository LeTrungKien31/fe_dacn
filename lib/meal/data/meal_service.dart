import '../../core/dio_client.dart';

class MealService {
  final DioClient _client;

  MealService(this._client);

  Future<void> add({required int foodId, required double servings}) async {
    try {
      await _client.post('/meal', data: {'foodId': foodId, 'servings': servings});
    } catch (e) {
      throw Exception('Failed to add meal: $e');
    }
  }

  Future<int> todayKcal() async {
    try {
      final res = await _client.get('/meal/today/total');
      return (res.data['totalKcal'] as num).toInt();
    } catch (e) {
      throw Exception('Failed to get today kcal: $e');
    }
  }

  Future<List<Map<String, dynamic>>> listFoods({String? query}) async {
    try {
      final r = await _client.get(
        '/foods',
        queryParameters: query != null ? {'q': query} : null,
      );
      return (r.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to list foods: $e');
    }
  }

  /// NEW: Get food detail with ingredients and cooking steps
  Future<Map<String, dynamic>> getFoodDetail(int foodId) async {
    try {
      final res = await _client.get('/foods/$foodId');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception('Failed to get food detail: $e');
    }
  }

  Future<List<Map<String, dynamic>>> history(DateTime from, DateTime to) async {
    try {
      final res = await _client.get(
        '/meal/history',
        queryParameters: {
          'from': from.toIso8601String().split('T')[0],
          'to': to.toIso8601String().split('T')[0],
        },
      );
      return (res.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get meal history: $e');
    }
  }
}