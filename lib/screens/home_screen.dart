import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/goals_provider.dart';
import '../models/meal.dart';
import 'food_table_screen.dart';
import 'add_meal_screen.dart';
import 'all_meals_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) setTheme;
  final ThemeMode themeMode;

  const HomeScreen({super.key, required this.setTheme, required this.themeMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'day';
  DateTime _selectedDate = DateTime.now();
  double _waterConsumed = 0;

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

  Map<String, double> get _totals {
    final meals = _filteredMeals;
    double calories = 0, proteins = 0, fats = 0, carbs = 0;
    for (var meal in meals) {
      calories += meal.totalCalories;
      proteins += meal.totalProteins;
      fats += meal.totalFats;
      carbs += meal.totalCarbs;
    }
    return {
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
    };
  }

  double _getGoalForPeriod(double dailyGoal) {
    switch (_period) {
      case 'week':
        return dailyGoal * 7;
      case 'month':
        int year = _selectedDate.year;
        int month = _selectedDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        final nextMonth = DateTime(year, month, 1);
        final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
        return dailyGoal * daysInMonth;
      default:
        return dailyGoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eat Fitness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить приём пищи',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMealScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodTableScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    setTheme: widget.setTheme,
                    themeMode: widget.themeMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer3<MealProvider, GoalsProvider, FoodProvider>(
        builder: (context, mealProvider, goalsProvider, foodProvider, child) {
          final totals = _totals;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 16),
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                _buildDashboard(totals, goalsProvider),
                const SizedBox(height: 16),
                _buildWaterTracker(goalsProvider),
                const SizedBox(height: 16),
                _buildLastMeal(mealProvider),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
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

  Widget _buildDashboard(Map<String, double> totals, GoalsProvider goals) {
    final calGoal = _getGoalForPeriod(goals.calories);
    final protGoal = _getGoalForPeriod(goals.proteins);
    final fatGoal = _getGoalForPeriod(goals.fats);
    final carbGoal = _getGoalForPeriod(goals.carbs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('КБЖУ за ${_getPeriodName()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressRing(
                  'Калории',
                  totals['calories']!,
                  calGoal,
                  Colors.orange,
                  '${totals['calories']!.toInt()} / ${calGoal.toInt()}',
                ),
                _buildProgressRing(
                  'Белки',
                  totals['proteins']!,
                  protGoal,
                  Colors.blue,
                  '${totals['proteins']!.toInt()} / ${protGoal.toInt()}',
                ),
                _buildProgressRing(
                  'Жиры',
                  totals['fats']!,
                  fatGoal,
                  Colors.red,
                  '${totals['fats']!.toInt()} / ${fatGoal.toInt()}',
                ),
                _buildProgressRing(
                  'Углеводы',
                  totals['carbs']!,
                  carbGoal,
                  Colors.green,
                  '${totals['carbs']!.toInt()} / ${carbGoal.toInt()}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodName() {
    switch (_period) {
      case 'week':
        return 'неделю';
      case 'month':
        return 'месяц';
      default:
        return 'день';
    }
  }

  Widget _buildProgressRing(
      String label, double value, double goal, Color color, String text) {
    final percent = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40,
          lineWidth: 8,
          percent: percent,
          center: Text('${((percent) * 100).toInt()}%',
              style: const TextStyle(fontSize: 12)),
          progressColor: color,
          backgroundColor: color.withOpacity(0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWaterTracker(GoalsProvider goals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вода',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _waterConsumed / goals.water,
              minHeight: 10,
              backgroundColor: Colors.blue.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_waterConsumed.toInt()} / ${goals.water.toInt()} мл'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          _waterConsumed =
                              (_waterConsumed - 250).clamp(0, double.infinity);
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _waterConsumed += 250;
                        });
                      },
                      child: const Text('+250 мл'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMeal(MealProvider mealProvider) {
    final lastMeal = mealProvider.lastMeal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Последний прием пищи',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllMealsScreen()),
                    );
                  },
                  child: const Text('Все приемы'),
                ),
              ],
            ),
            if (lastMeal != null) ...[
              const SizedBox(height: 8),
              Text('Тип: ${lastMeal.type}'),
              Text(DateFormat('HH:mm').format(lastMeal.date)),
              Text(
                  '${lastMeal.totalCalories.toInt()} ккал, ${lastMeal.totalProteins.toInt()}г белков'),
            ] else
              const Text('Нет записей о приемах пищи'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Быстрые действия',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              'Цели',
              Icons.flag,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalsScreen()),
                );
              },
            ),
            _buildActionButton(
              'Шаблоны',
              Icons.bookmark,
              Colors.blue,
              () {},
            ),
            _buildActionButton(
              'Статистика',
              Icons.bar_chart,
              Colors.orange,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
