import '../../core/dio_client.dart';

class MealService {
  final DioClient _client;

  MealService(this._client);

  Future<void> add({required int foodId, required double servings}) async {
    await _client.post('/meal', data: {'foodId': foodId, 'servings': servings});
  }

  Future<int> todayKcal() async {
    final res = await _client.get('/meal/today/total');
    return (res.data['totalKcal'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> listFoods({String? query}) async {
    final r = await _client.get(
      '/foods',
      queryParameters: query != null ? {'q': query} : null,
    );
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> history(DateTime from, DateTime to) async {
    final res = await _client.get(
      '/meal/history',
      queryParameters: {
        'from': from.toIso8601String().split('T')[0],
        'to': to.toIso8601String().split('T')[0],
      },
    );
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}