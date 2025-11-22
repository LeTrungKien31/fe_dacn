import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers.dart';
import 'data/water_service.dart';

final waterServiceProvider = Provider((ref) => WaterService(ref.read(dioClientProvider)));

final todayWaterProvider = FutureProvider<int>((ref) async {
  return ref.watch(waterServiceProvider).todayTotal();
});
