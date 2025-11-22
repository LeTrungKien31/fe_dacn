import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:health/provider.dart'; // đổi "health" đúng tên package của bạn

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water  = ref.watch(todayWaterProvider);
    final inKcal = ref.watch(todayMealKcalProvider);
    final outKcal= ref.watch(todayKcalOutProvider);

    // ignore: no_leading_underscores_for_local_identifiers
    int? _net(int? i, int? o) => (i != null && o != null) ? (i - o) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile("Nước hôm nay", water),
            const SizedBox(height: 8),
            _tile("Kcal nạp", inKcal),
            const SizedBox(height: 8),
            _tile("Kcal tiêu", outKcal),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final i = inKcal.asData?.value;
              final o = outKcal.asData?.value;
              final n = _net(i, o);
              return Text("Kcal net: ${n ?? '...'}",
                  style: Theme.of(context).textTheme.titleLarge);
            }),
            const Spacer(),
            Wrap(spacing: 12, runSpacing: 12, children: [
              ElevatedButton(
                onPressed: () async {
                  await ref.read(waterServiceProvider).add(250);
                  ref.invalidate(todayWaterProvider);
                },
                child: const Text('Ghi nước +250ml'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(mealServiceProvider)
                      .add(foodId: 1, servings: 1);
                  ref.invalidate(todayMealKcalProvider);
                },
                child: const Text('Ăn 1 chén cơm'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(activityServiceProvider).add(
                        name: 'Chạy bộ',
                        met: 7.5,
                        minutes: 20,
                        weightKg: 65,
                      );
                  ref.invalidate(todayKcalOutProvider);
                },
                child: const Text('Chạy bộ 20p'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, AsyncValue<int> v) {
    return v.when(
      data: (x) =>
          Text('$label: $x', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      loading: () => Text('$label: ...'),
      error: (e, _) => Text('$label: lỗi'),
    );
  }
}
