import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../provider.dart';
import 'meals_screen.dart';

class MealDetailScreen extends ConsumerWidget {
  final MealModel? meal;
  
  const MealDetailScreen({super.key, this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Default meal for demo if none passed
    final displayMeal = meal ?? const MealModel(
      id: 3,
      name: 'Canh cá nấu chua ngọt',
      imageUrl: 'fish_soup',
      kcal: 280,
      carbs: 18,
      protein: 20,
      fat: 12,
      isFavorite: true,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(displayMeal.name.toUpperCase()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(displayMeal),
            _buildNutritionInfo(displayMeal),
            _buildIngredients(),
            _buildInstructions(),
            const SizedBox(height: 20),
            _buildAddButton(context, ref, displayMeal),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(MealModel meal) {
    final emojis = {
      'hamburger': '🍔',
      'seafood_soup': '🍲',
      'fish_soup': '🐟',
      'spaghetti': '🍝',
      'chicken_rice': '🍗',
      'pho': '🍜',
    };
    
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Text(
          emojis[meal.imageUrl] ?? '🍽️',
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(MealModel meal) {
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
              _buildNutrientItem('${meal.kcal.toInt()}', 'Kcal', Colors.orange),
              _buildNutrientDivider(),
              _buildNutrientItem('${meal.protein.toInt()}', 'Protein', AppColors.waterBlue),
              _buildNutrientDivider(),
              _buildNutrientItem('${meal.carbs.toInt()}', 'Carbs', AppColors.primary),
              _buildNutrientDivider(),
              _buildNutrientItem('${meal.fat.toInt()}', 'Fat', Colors.purple),
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
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNutrientDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[300],
    );
  }

  Widget _buildIngredients() {
    final ingredients = [
      '300g cá nâu, làm sạch và cắt miếng',
      '1 củ hành tím, thái nhỏ',
      '2 củ tỏi, băm nhỏ',
      '1 củ gừng, băm nhỏ',
      '2 củ cà chua, thái hạt lựu',
      '2-3 quả cà chua chery, cắt đôi',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          ...ingredients.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('- ', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(item, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = [
      'Ướp cá với muối, tiêu, bột ngọt khoảng 15 phút.',
      'Phi thơm hành tỏi với dầu ăn.',
      'Cho cà chua vào xào mềm.',
      'Đổ nước vào đun sôi, nêm nếm gia vị.',
      'Cho cá vào nấu chín, thêm hành lá.',
    ];

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
          ...steps.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.key + 1}. ', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(entry.value, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, MealModel meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(mealServiceProvider).add(foodId: meal.id, servings: 1);
            ref.invalidate(todayMealKcalProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm ${meal.name} vào nhật ký')),
              );
              Navigator.pop(context);
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