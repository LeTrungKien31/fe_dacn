import '../core/dio_client.dart';

class WaterService {
  final DioClient _client;

  WaterService(this._client);

  Future<void> add(int amount) async {
    await _client.post('/water', data: {'amount': amount});
  }

  Future<int> todayTotal() async {
    final res = await _client.get('/water/today/total');
    return (res.data['totalMl'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> history(DateTime from, DateTime to) async {
    final res = await _client.get('/water/history', queryParameters: {
      'from': from.toIso8601String().split('T')[0],
      'to': to.toIso8601String().split('T')[0],
    });
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}