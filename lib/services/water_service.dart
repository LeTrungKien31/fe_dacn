import '../core/dio_client.dart';

class WaterService {
  final DioClient _client;

  WaterService(this._client);

  Future<void> add(int amount) async {
    try {
      await _client.post('/water', data: {'amount': amount});
    } catch (e) {
      throw Exception('Failed to add water: $e');
    }
  }

  Future<int> todayTotal() async {
    try {
      final res = await _client.get('/water/today/total');
      // Backend returns { "totalMl": 250, "goalMl": 2000, "percentage": 12.5, "goalReached": false }
      // We only need totalMl
      return (res.data['totalMl'] as num).toInt();
    } catch (e) {
      throw Exception('Failed to get today total: $e');
    }
  }

  Future<List<Map<String, dynamic>>> history(DateTime from, DateTime to) async {
    try {
      final res = await _client.get(
        '/water/history',
        queryParameters: {
          'from': from.toIso8601String().split('T')[0],
          'to': to.toIso8601String().split('T')[0],
        },
      );
      return (res.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get water history: $e');
    }
  }
}
