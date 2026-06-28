import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meal_planner/main.dart';

void main() {
  testWidgets('スプラッシュ画面が表示され、メイン画面へ遷移する', (tester) async {
    await initializeDateFormatting('ja_JP', null);

    await tester.pumpWidget(const ProviderScope(child: MealPlannerApp()));

    // スプラッシュ画面
    expect(find.text('Meal Planner'), findsOneWidget);

    // スプラッシュのタイマー(2秒)とフェード遷移を進める
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // メイン画面の4タブが表示される
    expect(find.text('献立'), findsOneWidget);
    expect(find.text('在庫'), findsOneWidget);
    expect(find.text('チラシ'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
