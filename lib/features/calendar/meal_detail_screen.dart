import 'package:flutter/material.dart';

import '../../models/meal.dart';

/// 献立詳細画面（F-05）。食材リストと調理手順を表示する。
class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(meal.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(label: Text(meal.category.label)),
          const SizedBox(height: 16),
          Text('食材', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (meal.ingredients.isEmpty)
            const Text('（食材情報なし）', style: TextStyle(color: Colors.grey))
          else
            for (final ingredient in meal.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('・'),
                    Expanded(child: Text(ingredient)),
                  ],
                ),
              ),
          const SizedBox(height: 24),
          Text('調理手順', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (meal.steps.isEmpty)
            const Text('（手順情報なし）', style: TextStyle(color: Colors.grey))
          else
            for (var i = 0; i < meal.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(meal.steps[i])),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
