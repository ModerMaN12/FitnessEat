import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/meal_provider.dart';
import '../providers/goals_provider.dart';
import '../models/meal.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'week';
  DateTime _selectedDate = DateTime.now();

  List<Meal> get _filteredMeals {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    switch (_period) {
      case 'week':
        return mealProvider.getMealsForWeek(_selectedDate);
      case 'month':
        return mealProvider.getMealsForMonth(_selectedDate);
      default:
        return mealProvider.getMealsForDate(_selectedDate);
    }
  }

  Map<String, double> get _averages {
    final meals = _filteredMeals;
    if (meals.isEmpty) {
      return {'calories': 0, 'proteins': 0, 'fats': 0, 'carbs': 0};
    }

    double calories = 0, proteins = 0, fats = 0, carbs = 0;
    for (var meal in meals) {
      calories += meal.totalCalories;
      proteins += meal.totalProteins;
      fats += meal.totalFats;
      carbs += meal.totalCarbs;
    }

    int days;
    if (_period == 'week') {
      days = 7;
    } else if (_period == 'month') {
      days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    } else {
      days = 1;
    }

    return {
      'calories': calories / days,
      'proteins': proteins / days,
      'fats': fats / days,
      'carbs': carbs / days,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: Consumer2<MealProvider, GoalsProvider>(
        builder: (context, mealProvider, goalsProvider, child) {
          final meals = _filteredMeals;
          final averages = _averages;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                _buildDateSelector(),
                const SizedBox(height: 24),
                _buildCaloriesChart(meals, goalsProvider),
                const SizedBox(height: 24),
                _buildNutrientsChart(meals),
                const SizedBox(height: 24),
                _buildAveragesCard(averages, goalsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'day', label: Text('День')),
        ButtonSegment(value: 'week', label: Text('Неделя')),
        ButtonSegment(value: 'month', label: Text('Месяц')),
      ],
      selected: {_period},
      onSelectionChanged: (selection) {
        setState(() {
          _period = selection.first;
        });
      },
    );
  }

  Widget _buildDateSelector() {
    String dateText;
    VoidCallback? onPrev;
    VoidCallback? onNext;

    if (_period == 'month') {
      dateText = DateFormat('MMMM yyyy', 'ru_RU').format(_selectedDate);
      onPrev = () {
        setState(() {
          if (_selectedDate.month > 1) {
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          } else {
            _selectedDate = DateTime(_selectedDate.year - 1, 12, 1);
          }
        });
      };
      onNext = () {
        setState(() {
          if (_selectedDate.month < 12) {
            _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          } else {
            _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
          }
        });
      };
    } else if (_period == 'week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateText = '${DateFormat('d MMM', 'ru_RU').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'ru_RU').format(endOfWeek)}';
      onPrev = () {
        setState(() {
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        });
      };
      onNext = () {
        setState(() {
          _selectedDate = _selectedDate.add(const Duration(days: 7));
        });
      };
    } else {
      dateText = DateFormat('EEEE, d MMMM yyyy', 'ru_RU').format(_selectedDate);
      onPrev = () {
        setState(() {
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        });
      };
      onNext = () {
        setState(() {
          _selectedDate = _selectedDate.add(const Duration(days: 1));
        });
      };
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Expanded(
          child: Text(
            dateText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _buildCaloriesChart(List<Meal> meals, GoalsProvider goals) {
    final dailyData = _getDailyCalories(meals);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Калории', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: goals.calories * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                            return Text(dailyData[value.toInt()].day);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dailyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.calories,
                          color: Colors.orange,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientsChart(List<Meal> meals) {
    final dailyData = _getDailyNutrients(meals);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('БЖУ по дням', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxNutrients(meals) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                            return Text(dailyData[value.toInt()].day);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dailyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.proteins,
                          color: Colors.blue,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: entry.value.fats,
                          color: Colors.red,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: entry.value.carbs,
                          color: Colors.green,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAveragesCard(Map<String, double> averages, GoalsProvider goals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Средние показатели', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAverageRow('Калории', averages['calories']!, goals.calories, Colors.orange),
            _buildAverageRow('Белки', averages['proteins']!, goals.proteins, Colors.blue),
            _buildAverageRow('Жиры', averages['fats']!, goals.fats, Colors.red),
            _buildAverageRow('Углеводы', averages['carbs']!, goals.carbs, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageRow(String label, double value, double goal, Color color) {
    final percent = goal > 0 ? (value / goal * 100).clamp(0, 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toInt()} / ${goal.toInt()} (${percent.toInt()}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  List<_DailyCalories> _getDailyCalories(List<Meal> meals) {
    final Map<String, double> dailyCalories = {};

    for (var meal in meals) {
      final day = DateFormat('d MMM', 'ru_RU').format(meal.date);
      dailyCalories[day] = (dailyCalories[day] ?? 0) + meal.totalCalories;
    }

    return dailyCalories.entries.map((e) => _DailyCalories(e.key, e.value)).toList();
  }

  List<_DailyNutrients> _getDailyNutrients(List<Meal> meals) {
    final Map<String, _DailyNutrients> dailyNutrients = {};

    for (var meal in meals) {
      final day = DateFormat('d MMM', 'ru_RU').format(meal.date);
      if (!dailyNutrients.containsKey(day)) {
        dailyNutrients[day] = _DailyNutrients(day, 0, 0, 0, 0);
      }
      dailyNutrients[day] = _DailyNutrients(
        day,
        dailyNutrients[day]!.calories + meal.totalCalories,
        dailyNutrients[day]!.proteins + meal.totalProteins,
        dailyNutrients[day]!.fats + meal.totalFats,
        dailyNutrients[day]!.carbs + meal.totalCarbs,
      );
    }

    return dailyNutrients.values.toList();
  }

  double _getMaxNutrients(List<Meal> meals) {
    final nutrients = _getDailyNutrients(meals);
    if (nutrients.isEmpty) return 100;
    return nutrients
        .map((e) => [e.proteins, e.fats, e.carbs])
        .expand((e) => e)
        .reduce((a, b) => a > b ? a : b);
  }
}

class _DailyCalories {
  final String day;
  final double calories;

  _DailyCalories(this.day, this.calories);
}

class _DailyNutrients {
  final String day;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  _DailyNutrients(this.day, this.calories, this.proteins, this.fats, this.carbs);
}
