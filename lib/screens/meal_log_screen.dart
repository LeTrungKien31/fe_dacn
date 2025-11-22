import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider.dart';

class MealLogScreen extends ConsumerWidget {
  const MealLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inKcal = ref.watch(todayMealKcalProvider);

    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _add(int foodId) async {
      await ref.read(mealServiceProvider).add(foodId: foodId, servings: 1);
      ref.invalidate(todayMealKcalProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã ghi bữa ăn')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi bữa ăn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            inKcal.when(
              data: (x) => Text(
                'Kcal nạp hôm nay: $x',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              loading: () => const Text('Đang tải...'),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _add(1), // foodId=1 (Cơm trắng 200kcal)
              child: const Text('Ăn 1 chén cơm (id=1)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final foods = await ref.read(mealServiceProvider).listFoods();
                if (!context.mounted) return;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => ListView(
                    children: foods
                        .map(
                          (f) => ListTile(
                            title: Text(f['name']),
                            subtitle: Text(
                              '${f['serving']} • ${f['kcalPerServing']} kcal',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _add(f['id']);
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
              },
              child: const Text('Chọn món khác...'),
            ),
          ],
        ),
      ),
    );
  }
}
