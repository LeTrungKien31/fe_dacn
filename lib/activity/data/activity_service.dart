import 'package:dio/dio.dart';
import '../../core/dio_client.dart';

class ActivityService {
  final DioClient _client;
  Dio get _dio => _client.dio;

  ActivityService(this._client);

  Future<void> add({
    required String name,
    required double met,
    required int minutes,
    required double weightKg,
  }) async {
    await _dio.post('/activity', data: {
      'name': name,
      'met': met,
      'minutes': minutes,
      'weightKg': weightKg,
    });
  }

  Future<int> todayKcalOut() async {
    final res = await _dio.get('/activity/today/total');
    return (res.data['totalKcal'] as num).toInt();
  }
}
