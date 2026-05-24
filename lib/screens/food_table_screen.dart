import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/food_provider.dart';
import '../models/food_item.dart';
import '../utils/platform_image.dart';

class FoodTableScreen extends StatefulWidget {
  const FoodTableScreen({super.key});

  @override
  State<FoodTableScreen> createState() => _FoodTableScreenState();
}

class _FoodTableScreenState extends State<FoodTableScreen> {
  String _searchQuery = '';
  bool _showComposite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Таблица продуктов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFoodDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск продуктов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Простые')),
              ButtonSegment(value: true, label: Text('Составные')),
            ],
            selected: {_showComposite},
            onSelectionChanged: (value) =>
                setState(() => _showComposite = value.first),
          ),
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                final foods = _showComposite
                    ? foodProvider.compositeFoods
                    : foodProvider.simpleFoods;
                final filtered = _searchQuery.isEmpty
                    ? foods
                    : foods
                        .where((f) => f.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Нет продуктов'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final food = filtered[index];
                    return ListTile(
                      leading: food.imagePath != null
                          ? CircleAvatar(
                              backgroundImage: PlatformImage.provider(food.imagePath!))
                          : CircleAvatar(
                              child: Text(food.name.substring(0, 1))),
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.isPer100g ? "на 100г: " : "всего: "}${food.calories.toInt()} ккал, Б: ${food.proteins.toInt()}, Ж: ${food.fats.toInt()}, У: ${food.carbs.toInt()}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Редактировать')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Удалить')),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            foodProvider.deleteFood(food.id);
                          } else if (value == 'edit') {
                            _showFoodDialog(context, food: food);
                          }
                        },
                      ),
                      onTap: () => _showFoodDialog(context, food: food),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompositeDishDialog(context),
        icon: const Icon(Icons.restaurant),
        label: const Text('Составное блюдо'),
      ),
    );
  }

  void _showFoodDialog(BuildContext context, {FoodItem? food}) {
    final nameController = TextEditingController(text: food?.name ?? '');
    final calController =
        TextEditingController(text: food?.calories.toString() ?? '');
    final protController =
        TextEditingController(text: food?.proteins.toString() ?? '');
    final fatController =
        TextEditingController(text: food?.fats.toString() ?? '');
    final carbController =
        TextEditingController(text: food?.carbs.toString() ?? '');
    bool isPer100g = food?.isPer100g ?? true;
    String? imagePath = food?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(food == null ? 'Добавить продукт' : 'Редактировать'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => imagePath = image.path);
                    }
                  },
                    child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        imagePath != null ? PlatformImage.provider(imagePath!) : null,
                    child: imagePath == null ? const Icon(Icons.add_a_photo) : null,
                  ),
                ),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название')),
                TextField(
                    controller: calController,
                    decoration: const InputDecoration(
                        labelText: 'Калории (на 100г или всего)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: protController,
                    decoration: const InputDecoration(labelText: 'Белки'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: fatController,
                    decoration: const InputDecoration(labelText: 'Жиры'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: carbController,
                    decoration: const InputDecoration(labelText: 'Углеводы'),
                    keyboardType: TextInputType.number),
                SwitchListTile(
                  title: const Text('Значения на 100г'),
                  value: isPer100g,
                  onChanged: (value) => setState(() => isPer100g = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final foodProvider =
                    Provider.of<FoodProvider>(context, listen: false);
                final newFood = FoodItem(
                  id: food?.id ?? DateTime.now().toString(),
                  name: nameController.text,
                  imagePath: imagePath,
                  calories: double.tryParse(calController.text) ?? 0,
                  proteins: double.tryParse(protController.text) ?? 0,
                  fats: double.tryParse(fatController.text) ?? 0,
                  carbs: double.tryParse(carbController.text) ?? 0,
                  isPer100g: isPer100g,
                );

                if (food == null) {
                  foodProvider.addFood(newFood);
                } else {
                  food.name = newFood.name;
                  food.imagePath = newFood.imagePath;
                  food.calories = newFood.calories;
                  food.proteins = newFood.proteins;
                  food.fats = newFood.fats;
                  food.carbs = newFood.carbs;
                  food.isPer100g = newFood.isPer100g;
                  foodProvider.updateFood(food);
                }
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompositeDishDialog(BuildContext context) {
    final nameController = TextEditingController();
    String? imagePath;
    final ingredients = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Создать составное блюдо'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => imagePath = image.path);
                    }
                  },
                    child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        imagePath != null ? PlatformImage.provider(imagePath!) : null,
                    child: imagePath == null ? const Icon(Icons.add_a_photo) : null,
                  ),
                ),
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название блюда')),
                const SizedBox(height: 16),
                const Text('Ингредиенты:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...ingredients.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ing = entry.value;
                  return ListTile(
                    title: Text(ing['name']),
                    subtitle:
                        Text('${ing['grams']}г - ${ing['calories']?.toInt()} ккал'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => ingredients.removeAt(i)),
                    ),
                  );
                }),
                ElevatedButton(
                  onPressed: () => _addIngredient(context, ingredients, setState),
                  child: const Text('Добавить ингредиент'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || ingredients.isEmpty) return;

                double totalCal = 0, totalProt = 0, totalFat = 0, totalCarb = 0;
                final ingredientList = <Ingredient>[];

                for (var ing in ingredients) {
                  totalCal += ing['calories'] ?? 0;
                  totalProt += ing['proteins'] ?? 0;
                  totalFat += ing['fats'] ?? 0;
                  totalCarb += ing['carbs'] ?? 0;
                  ingredientList.add(Ingredient(
                    foodItemId: ing['id'],
                    grams: ing['grams'],
                  ));
                }

                final totalWeight =
                    ingredients.fold(0.0, (sum, ing) => sum + ing['grams']);

                final foodProvider =
                    Provider.of<FoodProvider>(context, listen: false);

                final newFood = FoodItem(
                  id: DateTime.now().toString(),
                  name: nameController.text,
                  imagePath: imagePath,
                  calories: totalWeight > 0 ? (totalCal / totalWeight) * 100 : 0,
                  proteins:
                      totalWeight > 0 ? (totalProt / totalWeight) * 100 : 0,
                  fats: totalWeight > 0 ? (totalFat / totalWeight) * 100 : 0,
                  carbs: totalWeight > 0 ? (totalCarb / totalWeight) * 100 : 0,
                  isPer100g: true,
                  isComposite: true,
                  ingredients: ingredientList,
                );

                foodProvider.addFood(newFood);
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _addIngredient(BuildContext context,
      List<Map<String, dynamic>> ingredients, StateSetter setState) {
    String? selectedFoodId;
    final gramsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить ингредиент'),
        content: Consumer<FoodProvider>(
          builder: (context, foodProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  hint: const Text('Выберите продукт'),
                  value: selectedFoodId,
                  items: foodProvider.simpleFoods.map((food) {
                    return DropdownMenuItem(
                      value: food.id,
                      child: Text(food.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedFoodId = value,
                ),
                TextField(
                  controller: gramsController,
                  decoration: const InputDecoration(labelText: 'Граммы'),
                  keyboardType: TextInputType.number,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (selectedFoodId == null || gramsController.text.isEmpty) return;

              final foodProvider =
                  Provider.of<FoodProvider>(context, listen: false);
              final food = foodProvider.getFoodById(selectedFoodId!);
              if (food == null) return;

              final grams = double.tryParse(gramsController.text) ?? 0;

              setState(() {
                ingredients.add({
                  'id': food.id,
                  'name': food.name,
                  'grams': grams,
                  'calories': food.getCaloriesForAmount(grams),
                  'proteins': food.getProteinsForAmount(grams),
                  'fats': food.getFatsForAmount(grams),
                  'carbs': food.getCarbsForAmount(grams),
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
