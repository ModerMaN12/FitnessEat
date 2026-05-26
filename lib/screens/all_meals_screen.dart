import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meal_provider.dart';
import 'meal_detail_screen.dart';
import '../utils/platform_image.dart';

class AllMealsScreen extends StatefulWidget {
  const AllMealsScreen({super.key});

  @override
  State<AllMealsScreen> createState() => _AllMealsScreenState();
}

class _AllMealsScreenState extends State<AllMealsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minCalories;
  double? _maxCalories;
  double? _minProteins;
  double? _maxProteins;
  double? _minFats;
  double? _maxFats;
  double? _minCarbs;
  double? _maxCarbs;
  String? _sortBy;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История приемов пищи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.filterMeals(
            startDate: _startDate,
            endDate: _endDate,
            minCalories: _minCalories,
            maxCalories: _maxCalories,
            minProteins: _minProteins,
            maxProteins: _maxProteins,
            minFats: _minFats,
            maxFats: _maxFats,
            minCarbs: _minCarbs,
            maxCarbs: _maxCarbs,
            sortBy: _sortBy,
            ascending: _ascending,
          );

          if (meals.isEmpty) {
            return const Center(child: Text('Нет записей о приемах пищи'));
          }

          return Column(
            children: [
              if (_hasActiveFilters()) _buildActiveFilters(),
              Expanded(
                child: ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: meal.imagePath != null
                            ? CircleAvatar(
                                backgroundImage:
                                    PlatformImage.provider(meal.imagePath!))
                            : CircleAvatar(
                                child: Text(meal.type.substring(0, 1))),
                        title: Text(meal.type),
                        subtitle: Text(
                          '${DateFormat('dd.MM.yyyy HH:mm').format(meal.date)}\n'
                          '${meal.totalCalories.toInt()} ккал, Б: ${meal.totalProteins.toInt()}, Ж: ${meal.totalFats.toInt()}, У: ${meal.totalCarbs.toInt()}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              meal.isSynced ? Icons.cloud_done : Icons.cloud_outlined,
                              size: 16,
                              color: meal.isSynced ? Colors.green : Colors.grey,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  mealProvider.deleteMeal(meal.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MealDetailScreen(meal: meal),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        _minCalories != null ||
        _maxCalories != null ||
        _minProteins != null ||
        _maxProteins != null ||
        _minFats != null ||
        _maxFats != null ||
        _minCarbs != null ||
        _maxCarbs != null;
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          const Text('Фильтры активны', style: TextStyle(fontSize: 12)),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _minCalories = null;
                _maxCalories = null;
                _minProteins = null;
                _maxProteins = null;
                _minFats = null;
                _maxFats = null;
                _minCarbs = null;
                _maxCarbs = null;
                _sortBy = null;
                _ascending = false;
              });
            },
            child: const Text('Сбросить', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final calMinController =
        TextEditingController(text: _minCalories?.toString() ?? '');
    final calMaxController =
        TextEditingController(text: _maxCalories?.toString() ?? '');
    final protMinController =
        TextEditingController(text: _minProteins?.toString() ?? '');
    final protMaxController =
        TextEditingController(text: _maxProteins?.toString() ?? '');
    final fatMinController =
        TextEditingController(text: _minFats?.toString() ?? '');
    final fatMaxController =
        TextEditingController(text: _maxFats?.toString() ?? '');
    final carbMinController =
        TextEditingController(text: _minCarbs?.toString() ?? '');
    final carbMaxController =
        TextEditingController(text: _maxCarbs?.toString() ?? '');

    String? tempSortBy = _sortBy;
    bool tempAscending = _ascending;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Фильтры'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDateRangePicker(),
                const SizedBox(height: 16),
                const Text('Калории:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: calMinController,
                        decoration: const InputDecoration(labelText: 'От'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: calMaxController,
                        decoration: const InputDecoration(labelText: 'До'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Белки:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: protMinController,
                        decoration: const InputDecoration(labelText: 'От'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: protMaxController,
                        decoration: const InputDecoration(labelText: 'До'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Жиры:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fatMinController,
                        decoration: const InputDecoration(labelText: 'От'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fatMaxController,
                        decoration: const InputDecoration(labelText: 'До'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Углеводы:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbMinController,
                        decoration: const InputDecoration(labelText: 'От'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: carbMaxController,
                        decoration: const InputDecoration(labelText: 'До'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tempSortBy,
                  hint: const Text('Сортировка'),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('По дате')),
                    DropdownMenuItem(
                        value: 'calories', child: Text('По калориям')),
                    DropdownMenuItem(
                        value: 'proteins', child: Text('По белкам')),
                    DropdownMenuItem(value: 'fats', child: Text('По жирам')),
                    DropdownMenuItem(
                        value: 'carbs', child: Text('По углеводам')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => tempSortBy = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('По возрастанию'),
                  value: tempAscending,
                  onChanged: (value) {
                    setDialogState(() => tempAscending = value);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _minCalories = double.tryParse(calMinController.text);
                _maxCalories = double.tryParse(calMaxController.text);
                _minProteins = double.tryParse(protMinController.text);
                _maxProteins = double.tryParse(protMaxController.text);
                _minFats = double.tryParse(fatMinController.text);
                _maxFats = double.tryParse(fatMaxController.text);
                _minCarbs = double.tryParse(carbMinController.text);
                _maxCarbs = double.tryParse(carbMaxController.text);
                _sortBy = tempSortBy;
                _ascending = tempAscending;
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _startDate = date);
            },
            child: Text(_startDate != null
                ? DateFormat('dd.MM.yyyy').format(_startDate!)
                : 'От даты'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _endDate = date);
            },
            child: Text(_endDate != null
                ? DateFormat('dd.MM.yyyy').format(_endDate!)
                : 'До даты'),
          ),
        ),
      ],
    );
  }
}
