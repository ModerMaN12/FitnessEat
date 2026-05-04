import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goals_provider.dart';
import '../models/goals.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late TextEditingController _caloriesController;
  late TextEditingController _proteinsController;
  late TextEditingController _fatsController;
  late TextEditingController _carbsController;
  late TextEditingController _waterController;

  @override
  void initState() {
    super.initState();
    final goals = Provider.of<GoalsProvider>(context, listen: false).goals;
    _caloriesController =
        TextEditingController(text: goals?.calories.toInt().toString() ?? '2000');
    _proteinsController =
        TextEditingController(text: goals?.proteins.toInt().toString() ?? '150');
    _fatsController =
        TextEditingController(text: goals?.fats.toInt().toString() ?? '70');
    _carbsController =
        TextEditingController(text: goals?.carbs.toInt().toString() ?? '250');
    _waterController =
        TextEditingController(text: goals?.water.toInt().toString() ?? '2000');
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цели по КБЖУ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Установите дневные нормы:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGoalField('Калории (ккал)', _caloriesController, Colors.orange),
            _buildGoalField('Белки (г)', _proteinsController, Colors.blue),
            _buildGoalField('Жиры (г)', _fatsController, Colors.red),
            _buildGoalField('Углеводы (г)', _carbsController, Colors.green),
            _buildGoalField('Вода (мл)', _waterController, Colors.blue),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('Сохранить цели'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalField(
      String label, TextEditingController controller, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  void _saveGoals() {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    final newGoals = Goals(
      calories: double.tryParse(_caloriesController.text) ?? 2000,
      proteins: double.tryParse(_proteinsController.text) ?? 150,
      fats: double.tryParse(_fatsController.text) ?? 70,
      carbs: double.tryParse(_carbsController.text) ?? 250,
      water: double.tryParse(_waterController.text) ?? 2000,
    );

    goalsProvider.updateGoals(newGoals);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Цели сохранены')),
    );
  }
}
