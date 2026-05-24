import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/meal.dart';
import '../utils/platform_image.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали: ${meal.type}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PlatformImage.image(meal.imagePath!),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о приеме',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                        'Дата: ${DateFormat('dd MMMM yyyy, HH:mm').format(meal.date)}'),
                    Text('Тип: ${meal.type}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общие показатели КБЖУ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrient('Калории',
                            meal.totalCalories.toInt(), 'ккал', Colors.orange),
                        _buildNutrient('Белки', meal.totalProteins.toInt(), 'г',
                            Colors.blue),
                        _buildNutrient(
                            'Жиры', meal.totalFats.toInt(), 'г', Colors.red),
                        _buildNutrient('Углеводы',
                            meal.totalCarbs.toInt(), 'г', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Состав приема пищи:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                return Column(
                  children: meal.items.map((item) {
                    final food = foodProvider.getFoodById(item.foodItemId);
                    final calories = food?.getCaloriesForAmount(item.grams) ?? 0;
                    final proteins = food?.getProteinsForAmount(item.grams) ?? 0;
                    final fats = food?.getFatsForAmount(item.grams) ?? 0;
                    final carbs = food?.getCarbsForAmount(item.grams) ?? 0;

                    return Card(
                      child: ListTile(
                        title: Text(item.foodName ?? food?.name ?? 'Неизвестно'),
                        subtitle: Text(
                            '${item.grams.toStringAsFixed(0)}г - ${calories.toInt()} ккал\n'
                            'Б: ${proteins.toInt()}г, Ж: ${fats.toInt()}г, У: ${carbs.toInt()}г'),
                        leading: CircleAvatar(
                          child: Text(
                              (item.foodName ?? food?.name ?? '?').substring(0, 1)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrient(String label, int value, String unit, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
