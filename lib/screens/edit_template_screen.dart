import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/template_provider.dart';
import '../providers/food_provider.dart';
import '../models/meal_template.dart';
import '../models/food_item.dart';

class EditTemplateScreen extends StatefulWidget {
  final MealTemplate template;

  const EditTemplateScreen({super.key, required this.template});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  late TextEditingController _nameController;
  late String _selectedType;
  final List<TemplateItem> _items = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _selectedType = widget.template.type;
    _items.addAll(widget.template.items.map((item) => TemplateItem(
          foodItemId: item.foodItemId,
          grams: item.grams,
          foodName: item.foodName,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.id.isEmpty ? 'Новый шаблон' : 'Редактирование'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTemplateInfo(),
          const Divider(height: 1),
          Expanded(child: _buildItemsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFoodSearch(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название шаблона',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип приёма',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('Завтрак')),
              DropdownMenuItem(value: 'lunch', child: Text('Обед')),
              DropdownMenuItem(value: 'dinner', child: Text('Ужин')),
              DropdownMenuItem(value: 'snack', child: Text('Перекус')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет добавленных продуктов',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final food = foodProvider.getFoodById(item.foodItemId);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.foodName ?? 'Неизвестно'),
                subtitle: Text(
                    '${item.grams}г - ${food?.getCaloriesForAmount(item.grams).toInt() ?? 0} ккал'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editItemGrams(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFoodSearch(BuildContext context) {
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
                constraints:
                    BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: Consumer<FoodProvider>(
                  builder: (context, foodProvider, child) {
                    final foods = query.isEmpty
                        ? foodProvider.foods
                        : foodProvider.searchFoods(query);
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: foods.length,
                      itemBuilder: (context, index) {
                        final food = foods[index];
                        return ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                              '${food.calories.toInt()} ккал на ${food.isPer100g ? "100г" : "весь продукт"}'),
                          onTap: () {
                            Navigator.of(bottomSheetContext).pop(food);
                          },
                        );
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
                _items.add(TemplateItem(
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

  void _editItemGrams(int index) {
    final controller =
        TextEditingController(text: _items[index].grams.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить граммовку'),
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
                _items[index].grams =
                    double.tryParse(controller.text) ?? _items[index].grams;
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _saveTemplate() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название шаблона')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один продукт')),
      );
      return;
    }

    final templateProvider =
        Provider.of<TemplateProvider>(context, listen: false);

    final updatedTemplate = MealTemplate(
      id: widget.template.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : widget.template.id,
      name: _nameController.text,
      type: _selectedType,
      items: _items,
    );

    if (widget.template.id.isEmpty) {
      templateProvider.addTemplate(updatedTemplate);
    } else {
      templateProvider.updateTemplate(updatedTemplate);
    }

    Navigator.pop(context);
  }
}
