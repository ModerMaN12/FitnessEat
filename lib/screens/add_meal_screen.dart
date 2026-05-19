import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/food_provider.dart';
import '../providers/meal_provider.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/meal_template.dart';

class AddMealScreen extends StatefulWidget {
  final MealTemplate? template;

  const AddMealScreen({super.key, this.template});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String _mealType = 'Завтрак';
  final List<String> _mealTypes = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];
  late DateTime _mealDate;
  String? _imagePath;
  final List<MealItemData> _selectedItems = [];
  double _totalCalories = 0;
  double _totalProteins = 0;
  double _totalFats = 0;
  double _totalCarbs = 0;

  @override
  void initState() {
    super.initState();
    _mealDate = DateTime.now();
    if (widget.template != null) {
      _mealType = _mapTemplateTypeToMealType(widget.template!.type);
      for (var item in widget.template!.items) {
        _selectedItems.add(MealItemData(
          foodItemId: item.foodItemId,
          foodName: item.foodName,
          grams: item.grams,
        ));
      }
    }
  }

  String _mapTemplateTypeToMealType(String templateType) {
    switch (templateType) {
      case 'breakfast':
        return 'Завтрак';
      case 'lunch':
        return 'Обед';
      case 'dinner':
        return 'Ужин';
      case 'snack':
        return 'Перекус';
      default:
        return 'Завтрак';
    }
  }

  void _calculateTotals(FoodProvider foodProvider) {
    _totalCalories = 0;
    _totalProteins = 0;
    _totalFats = 0;
    _totalCarbs = 0;

    for (var item in _selectedItems) {
      final food = foodProvider.getFoodById(item.foodItemId);
      if (food != null) {
        _totalCalories += food.getCaloriesForAmount(item.grams);
        _totalProteins += food.getProteinsForAmount(item.grams);
        _totalFats += food.getFatsForAmount(item.grams);
        _totalCarbs += food.getCarbsForAmount(item.grams);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить прием пищи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveMeal,
          ),
        ],
      ),
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          _calculateTotals(foodProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealTypeSelector(),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildImagePicker(),
                const SizedBox(height: 16),
                _buildFoodSelector(context, foodProvider),
                const SizedBox(height: 16),
                _buildSelectedItems(foodProvider),
                const SizedBox(height: 16),
                _buildTotals(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return SegmentedButton<String>(
      segments: _mealTypes
          .map((type) => ButtonSegment(value: type, label: Text(type)))
          .toList(),
      selected: {_mealType},
      onSelectionChanged: (selection) {
        setState(() {
          _mealType = selection.first;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _mealDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('ru', 'RU'),
        );
        if (picked != null) {
          setState(() {
            _mealDate = DateTime(picked.year, picked.month, picked.day,
                _mealDate.hour, _mealDate.minute);
          });
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                _formatDate(_mealDate),
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.edit, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() => _imagePath = image.path);
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_imagePath!), fit: BoxFit.cover),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  Text('Добавить фото блюда'),
                ],
              ),
      ),
    );
  }

  Widget _buildFoodSelector(BuildContext context, FoodProvider foodProvider) {
    return ElevatedButton.icon(
      onPressed: () => _showFoodSearch(context, foodProvider),
      icon: const Icon(Icons.add),
      label: const Text('Добавить продукты'),
    );
  }

  void _showFoodSearch(BuildContext context, FoodProvider foodProvider) {
    String query = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Поиск продуктов...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: foodProvider.searchFoods(query).length,
                  itemBuilder: (context, index) {
                    final food = foodProvider.searchFoods(query)[index];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                          '${food.calories.toInt()} ккал на ${food.isPer100g ? "100г" : "весь продукт"}'),
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop(food);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((value) {
      if (value != null && value is FoodItem) {
        _addFoodItem(value);
      }
    });
  }

  void _addFoodItem(FoodItem food) {
    final gramsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Добавить ${food.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Продукт: ${food.name}\n${food.isPer100g ? "На 100г: " : "Всего: "}${food.calories.toInt()} ккал'),
            TextField(
              controller: gramsController,
              decoration: InputDecoration(
                labelText: food.isPer100g ? 'Граммы' : 'Использовать весь продукт',
                hintText: food.isPer100g ? '100' : '1',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final grams = double.tryParse(gramsController.text) ??
                  (food.isPer100g ? 100 : 1);
              setState(() {
                _selectedItems.add(MealItemData(
                  foodItemId: food.id,
                  foodName: food.name,
                  grams: grams,
                ));
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItems(FoodProvider foodProvider) {
    if (_selectedItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Нет добавленных продуктов'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Выбранные продукты:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._selectedItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final food = foodProvider.getFoodById(item.foodItemId);

              return ListTile(
                title: Text(item.foodName ?? 'Неизвестно'),
                subtitle: Text('${item.grams}г - '
                    '${food?.getCaloriesForAmount(item.grams).toInt()} ккал'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _selectedItems.removeAt(i)),
                ),
                onTap: () => _editItemGrams(i, food),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _editItemGrams(int index, FoodItem? food) {
    if (food == null) return;
    final controller =
        TextEditingController(text: _selectedItems[index].grams.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить граммовку'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Граммы'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedItems[index].grams =
                    double.tryParse(controller.text) ??
                        _selectedItems[index].grams;
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Итого за прием пищи:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem('Калории', _totalCalories.toInt(), Colors.orange),
                _buildTotalItem('Белки', _totalProteins.toInt(), Colors.blue),
                _buildTotalItem('Жиры', _totalFats.toInt(), Colors.red),
                _buildTotalItem('Углеводы', _totalCarbs.toInt(), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _saveMeal() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один продукт')),
      );
      return;
    }

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    final items = _selectedItems.map((item) {
      final food = foodProvider.getFoodById(item.foodItemId);
      return MealItem(
        foodItemId: item.foodItemId,
        grams: item.grams,
        foodName: item.foodName,
      )..calories = food?.getCaloriesForAmount(item.grams) ?? 0
        ..proteins = food?.getProteinsForAmount(item.grams) ?? 0
        ..fats = food?.getFatsForAmount(item.grams) ?? 0
        ..carbs = food?.getCarbsForAmount(item.grams) ?? 0;
    }).toList();

    final meal = Meal(
      id: DateTime.now().toString(),
      date: _mealDate,
      type: _mealType,
      items: items,
      imagePath: _imagePath,
      totalCalories: _totalCalories,
      totalProteins: _totalProteins,
      totalFats: _totalFats,
      totalCarbs: _totalCarbs,
    );

    mealProvider.addMeal(meal);
    Navigator.pop(context);
  }
}

class MealItemData {
  String foodItemId;
  String? foodName;
  double grams;

  MealItemData({
    required this.foodItemId,
    this.foodName,
    required this.grams,
  });
}
