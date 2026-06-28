import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // カレンダー等で日本語の日付フォーマットを使うため初期化する。
  await initializeDateFormatting('ja_JP', null);
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env が見つからなくても起動は継続する（AI生成時に明確なエラーを表示）。
  }
  runApp(const ProviderScope(child: MealPlannerApp()));
}

class MealPlannerApp extends StatelessWidget {
  const MealPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      // 表示言語は日本語固定（日付選択ダイアログ等を含む）。
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
