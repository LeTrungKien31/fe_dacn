import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../provider.dart';
import 'meals_screen.dart';

// Provider để fetch food detail
final foodDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, foodId) async {
  return ref.watch(mealServiceProvider).getFoodDetail(foodId);
});

class MealDetailScreen extends ConsumerStatefulWidget {
  final MealModel? meal;

  const MealDetailScreen({super.key, this.meal});

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  double _servings = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHI TIẾT MÓN ĂN')),
        body: const Center(child: Text('Không có thông tin món ăn')),
      );
    }

    final foodDetail = ref.watch(foodDetailProvider(widget.meal!.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.meal!.name.toUpperCase()),
      ),
      body: foodDetail.when(
        data: (detail) => _buildContent(detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Lỗi: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(foodDetailProvider(widget.meal!.id)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> detail) {
    final meal = widget.meal!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(detail),
          _buildNutritionInfo(detail),
          _buildServingsSelector(),
          // if (detail['ingredients'] != null &&
          //     (detail['ingredients'] as List).isNotEmpty)
          //   _buildIngredients(detail['ingredients'] as List),
          // if (detail['cookingSteps'] != null &&
          //     (detail['cookingSteps'] as List).isNotEmpty)
          //   _buildInstructions(detail['cookingSteps'] as List),
          const SizedBox(height: 20),
          _buildAddButton(context, meal),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Hiển thị hình ảnh món ăn từ imageUrl backend
  Widget _buildImage(Map<String, dynamic> detail) {
    final imageUrl = detail['imageUrl'] as String?;

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: imageUrl == null || imageUrl.isEmpty
          ? const Center(
              child: Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.grey,
              ),
            )
          : ClipRRect(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
    );
  }

  Widget _buildNutritionInfo(Map<String, dynamic> detail) {
    final kcal = ((detail['kcalPerServing'] as num?) ?? 0) * _servings;
    final protein = ((detail['protein'] as num?) ?? 0) * _servings;
    final carbs = ((detail['carbs'] as num?) ?? 0) * _servings;
    final fat = ((detail['fat'] as num?) ?? 0) * _servings;

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

  /// Chọn số phần ăn – bước nhảy 1, min 1, max 10
  Widget _buildServingsSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Số phần ăn:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _servings > 1
                    ? () => setState(() => _servings -= 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _servings.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _servings < 10
                    ? () => setState(() => _servings += 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildIngredients(List ingredients) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               width: 36,
  //               height: 36,
  //               decoration: BoxDecoration(
  //                 color: Colors.green[100],
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Center(
  //                 child: Text('🥗', style: TextStyle(fontSize: 20)),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             const Text(
  //               'Nguyên liệu',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         ...ingredients.map(
  //           (item) => Padding(
  //             padding: const EdgeInsets.only(left: 8, bottom: 8),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text('• ', style: TextStyle(fontSize: 15)),
  //                 Expanded(
  //                   child: Text(
  //                     '${item['name']} - ${item['quantity']}',
  //                     style: const TextStyle(fontSize: 15),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildInstructions(List steps) {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               width: 36,
  //               height: 36,
  //               decoration: BoxDecoration(
  //                 color: Colors.orange[100],
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Center(
  //                 child: Text('📝', style: TextStyle(fontSize: 20)),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             const Text(
  //               'Cách làm',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         ...steps.map(
  //           (step) => Padding(
  //             padding: const EdgeInsets.only(left: 8, bottom: 12),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   '${step['stepNumber']}. ',
  //                   style: const TextStyle(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: Text(
  //                     step['description'] ?? '',
  //                     style: const TextStyle(fontSize: 15),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAddButton(BuildContext context, MealModel meal) {
    final servingsText = _servings.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await ref
                  .read(mealServiceProvider)
                  .add(foodId: meal.id, servings: _servings);
              ref.invalidate(todayMealKcalProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã thêm ${meal.name} ($servingsText phần) vào nhật ký',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Thêm $servingsText phần vào bữa ăn',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
