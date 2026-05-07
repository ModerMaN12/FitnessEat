import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/template_provider.dart';
import '../models/meal_template.dart';
import 'add_meal_screen.dart';
import 'edit_template_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны приёмов'),
      ),
      body: Consumer<TemplateProvider>(
        builder: (context, templateProvider, child) {
          final templates = templateProvider.templates;

          if (templates.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет сохранённых шаблонов',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, template);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, MealTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(template.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getTypeIcon(template.type), color: _getTypeColor(template.type)),
        ),
        title: Text(template.name),
        subtitle: Text('${template.type} • ${template.items.length} продуктов'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'use',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text('Использовать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Редактировать'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Удалить', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'use') {
              _useTemplate(context, template);
            } else if (value == 'edit') {
              _editTemplate(context, template);
            } else if (value == 'delete') {
              _deleteTemplate(context, template.id);
            }
          },
        ),
      ),
    );
  }

  void _useTemplate(BuildContext context, MealTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMealScreen(template: template),
      ),
    );
  }

  void _editTemplate(BuildContext context, MealTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTemplateScreen(template: template),
      ),
    );
  }

  void _deleteTemplate(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<TemplateProvider>(context, listen: false)
                  .deleteTemplate(id);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context, {MealTemplate? template}) {
    final nameController = TextEditingController(text: template?.name ?? '');
    String selectedType = template?.type ?? 'breakfast';
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          title: Text(template == null ? 'Новый шаблон' : 'Редактировать шаблон'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название шаблона',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
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
                    selectedType = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final templateProvider =
                      Provider.of<TemplateProvider>(dialogContext, listen: false);

                  final newTemplate = MealTemplate(
                    id: template?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    type: selectedType,
                    items: template?.items ?? [],
                  );

                  if (template == null) {
                    templateProvider.addTemplate(newTemplate);
                    Navigator.pop(dialogContext);
                    if (outerContext.mounted) {
                      Navigator.push(
                        outerContext,
                        MaterialPageRoute(
                          builder: (_) => EditTemplateScreen(template: newTemplate),
                        ),
                      );
                    }
                  } else {
                    templateProvider.updateTemplate(newTemplate);
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
}
