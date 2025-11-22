import 'package:dio/dio.dart';
import '../../core/dio_client.dart';

class WaterService {
  final DioClient _client;
  Dio get _dio => _client.dio;

  WaterService(this._client);

  Future<void> add(int amount) async {
    await _dio.post('/water', data: {'amount': amount});
  }

  Future<int> todayTotal() async {
    final res = await _dio.get('/water/today/total');
    return (res.data['totalMl'] as num).toInt();
  }
}
