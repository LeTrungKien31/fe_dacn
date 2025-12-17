import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider.dart';

class MealModel {
  final int id;
  final String name;
  final String? imageUrl;
  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
  final bool isFavorite;

  const MealModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.isFavorite = false,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      kcal: (json['kcalPerServing'] as num).toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      isFavorite: false,
    );
  }
}

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});
  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final _searchController = TextEditingController();
  List<MealModel> _allMeals = [];
  List<MealModel> _filteredMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      setState(() => _isLoading = true);
      final foods = await ref.read(mealServiceProvider).listFoods();
      setState(() {
        _allMeals = foods.map((f) => MealModel.fromJson(f)).toList();
        _filteredMeals = _allMeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMeals = _allMeals;
      } else {
        _filteredMeals = _allMeals
            .where((m) => m.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _addMealToLog(MealModel meal) async {
    await ref.read(mealServiceProvider).add(foodId: meal.id, servings: 1);
    ref.invalidate(todayMealKcalProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${meal.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ignore: unused_local_variable
    final favorites = _filteredMeals.where((m) => m.isFavorite).toList();
    final others = _filteredMeals.where((m) => !m.isFavorite).toList();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MÓN ĂN'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeals,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // if (favorites.isNotEmpty) ...[
              //   Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     child: Text('Yêu thích',
              //         style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              //   ),
              //   const SizedBox(height: 12),
              //   _buildMealsGrid(favorites),
              // ],
              if (others.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text('Tất cả',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ),
                _buildMealsGrid(others),
              ],
              if (_filteredMeals.isEmpty) ...[
                const SizedBox(height: 100),
                const Center(child: Text('Không tìm thấy món ăn nào')),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealsGrid(List<MealModel> meals) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: meals.length,
      itemBuilder: (ctx, i) => _buildMealCard(meals[i]),
    );
  }

  Widget _buildMealCard(MealModel meal) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/meal/detail', arguments: meal),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                      ? Image.network(
                          meal.imageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Center(child: _buildMealEmoji(meal)),
                          ),
                        )
                      : Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Center(child: _buildMealEmoji(meal)),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        meal.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: meal.isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildNutrientChip('${meal.kcal.toInt()}', 'KCal'),
                      _buildNutrientChip('${meal.carbs.toInt()}', 'Carbs'),
                      _buildNutrientChip('${meal.protein.toInt()}', 'Protein'),
                      _buildNutrientChip('${meal.fat.toInt()}', 'Fat'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMealEmoji(MealModel meal) {
    return Text(_getMealEmoji(meal.imageUrl ?? meal.name), 
        style: const TextStyle(fontSize: 48));
  }

  String _getMealEmoji(String key) {
    final emojis = {
      'hamburger': '🍔', 'seafood_soup': '🍲', 'fish_soup': '🐟',
      'spaghetti': '🍝', 'chicken_rice': '🍗', 'pho': '🍜',
      'burger': '🍔', 'soup': '🍲', 'fish': '🐟', 'pasta': '🍝',
      'chicken': '🍗', 'noodle': '🍜', 'rice': '🍚', 'sandwich': '🥪',
    };
    final lowerKey = key.toLowerCase();
    for (var entry in emojis.entries) {
      if (lowerKey.contains(entry.key)) return entry.value;
    }
    return '🍽️';
  }
}