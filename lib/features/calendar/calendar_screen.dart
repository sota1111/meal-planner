import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/meal.dart';
import '../../providers/meals_provider.dart';
import '../../utils/slide_route.dart';
import '../generate/generate_screen.dart';
import 'meal_detail_screen.dart';

/// 献立カレンダー画面（F-01〜F-05）。
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final selectedMeals = meals[normalizeDate(_selectedDay)] ?? const <Meal>[];

    return Scaffold(
      appBar: AppBar(title: const Text('献立カレンダー')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          slideRoute(const GenerateScreen()),
        ),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('献立を自動生成'),
      ),
      body: Column(
        children: [
          TableCalendar<Meal>(
            locale: 'ja_JP',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            eventLoader: (day) => meals[normalizeDate(day)] ?? const [],
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: const CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _DayMealsView(
              date: _selectedDay,
              meals: selectedMeals,
            ),
          ),
        ],
      ),
    );
  }
}

/// 選択日の献立一覧（未登録なら空状態を表示）。
class _DayMealsView extends StatelessWidget {
  final DateTime date;
  final List<Meal> meals;

  const _DayMealsView({required this.date, required this.meals});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('M月d日(E)', 'ja_JP').format(date);

    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_meals, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '$dateLabel の献立はまだありません',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              '「献立を自動生成」から作成できます',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final meal in meals)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(meal.category.label)),
              title: Text(meal.name),
              subtitle: meal.ingredients.isEmpty
                  ? null
                  : Text(
                      meal.ingredients.join('、'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                slideRoute(MealDetailScreen(meal: meal)),
              ),
            ),
          ),
      ],
    );
  }
}
