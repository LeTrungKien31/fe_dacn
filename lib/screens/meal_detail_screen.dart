import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../provider.dart';
import 'meals_screen.dart';

// Provider để lấy chi tiết món ăn - FIX: Thêm .autoDispose
final foodDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((
  ref,
  foodId,
) async {
  return ref.watch(mealServiceProvider).getFoodDetail(foodId);
});

class MealDetailScreen extends ConsumerWidget {
  final MealModel? meal;

  const MealDetailScreen({super.key, this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHI TIẾT MÓN ĂN')),
        body: const Center(child: Text('Không có thông tin món ăn')),
      );
    }

    final foodDetail = ref.watch(foodDetailProvider(meal!.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(meal!.name.toUpperCase()),
      ),
      body: foodDetail.when(
        data: (data) => _buildContent(context, ref, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          // Log error for debugging
          debugPrint('Error loading food detail: $e');
          debugPrint('Stack trace: $st');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Lỗi tải chi tiết món ăn',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    e.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(foodDetailProvider(meal!.id)),
                  child: const Text('Thử lại'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    // Parse ingredients - handle both null and empty list
    final ingredientsData = data['ingredients'];
    final ingredients = ingredientsData is List
        ? ingredientsData.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // Parse cooking steps - handle both null and empty list
    final stepsData = data['cookingSteps'];
    final cookingSteps = stepsData is List
        ? stepsData.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(data),
          _buildNutritionInfo(data),
          if (data['description'] != null &&
              (data['description'] as String).isNotEmpty)
            _buildDescription(data['description']),
          if (ingredients.isNotEmpty) _buildIngredients(ingredients),
          if (cookingSteps.isNotEmpty) _buildInstructions(cookingSteps),
          const SizedBox(height: 20),
          _buildAddButton(context, ref, data),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> data) {
    final emojis = {
      'rice': '🍚',
      'pho': '🍜',
      'banh_mi': '🥖',
      'bun_cha': '🍲',
      'goi_cuon': '🌯',
      'fish': '🐟',
      'hamburger': '🍔',
      'seafood_soup': '🍲',
      'fish_soup': '🐟',
      'spaghetti': '🍝',
      'chicken_rice': '🍗',
    };

    final imageUrl = data['imageUrl'] as String?;

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  emojis[imageUrl] ?? '🍽️',
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            )
          : Center(
              child: Text(
                emojis[imageUrl ?? ''] ?? '🍽️',
                style: const TextStyle(fontSize: 80),
              ),
            ),
    );
  }

  Widget _buildNutritionInfo(Map<String, dynamic> data) {
    final kcal = data['kcalPerServing'] as num? ?? 0;
    final protein = data['protein'] as num? ?? 0;
    final carbs = data['carbs'] as num? ?? 0;
    final fat = data['fat'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Giá trị dinh dưỡng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNutrientItem('${kcal.toInt()}', 'Kcal', Colors.orange),
              _buildNutrientDivider(),
              _buildNutrientItem(
                '${protein.toInt()}g',
                'Protein',
                AppColors.waterBlue,
              ),
              _buildNutrientDivider(),
              _buildNutrientItem(
                '${carbs.toInt()}g',
                'Carbs',
                AppColors.primary,
              ),
              _buildNutrientDivider(),
              _buildNutrientItem('${fat.toInt()}g', 'Fat', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildNutrientDivider() {
    return Container(width: 1, height: 40, color: Colors.grey[300]);
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildIngredients(List<Map<String, dynamic>> ingredients) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🥗', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nguyên liệu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ingredients.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      '${item['name']} - ${item['quantity']}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(List<Map<String, dynamic>> steps) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📝', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cách làm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${step['stepNumber']}. ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step['description'],
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await ref
                  .read(mealServiceProvider)
                  .add(foodId: data['id'] as int, servings: 1);
              ref.invalidate(todayMealKcalProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm ${data['name']} vào nhật ký'),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi thêm món ăn: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Thêm vào bữa ăn', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}