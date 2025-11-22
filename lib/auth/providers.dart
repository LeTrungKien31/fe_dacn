import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/token_storage.dart';
import '../core/dio_client.dart';
import '../services/auth_service.dart';
import '../services/water_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(tokenStorageProvider);
  return DioClient(storage);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.read(dioClientProvider);
  final storage = ref.read(tokenStorageProvider);
  return AuthService(dio, storage);
});

final waterServiceProvider = Provider<WaterService>((ref) {
  final dio = ref.read(dioClientProvider);
  return WaterService(dio);
});

final meProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(authServiceProvider).me();
});

final todayWaterProvider = FutureProvider<int>((ref) async {
  return ref.watch(waterServiceProvider).todayTotal();
});
