import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider.dart';

class WaterLogScreen extends ConsumerWidget {
  const WaterLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWaterProvider);

    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _add(int ml) async {
      await ref.read(waterServiceProvider).add(ml);
      ref.invalidate(todayWaterProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã ghi +$ml ml')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi nước')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            today.when(
              data: (x) => Text(
                'Hôm nay: $x ml',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              loading: () => const Text('Đang tải...'),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () => _add(200),
                  child: const Text('+200ml'),
                ),
                FilledButton(
                  onPressed: () => _add(250),
                  child: const Text('+250ml'),
                ),
                FilledButton(
                  onPressed: () => _add(500),
                  child: const Text('+500ml'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
