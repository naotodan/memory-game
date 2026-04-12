import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants.dart';
import 'features/home/home_screen.dart';
import 'features/game/game_screen.dart';
import 'features/result/result_screen.dart';

void main() {
  runApp(
    // Riverpod の状態管理を有効化するためにルートを ProviderScope でラップ
    const ProviderScope(
      child: MemoryGameApp(),
    ),
  );
}

/// アプリのルートウィジェット
class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // 名前付きルートで画面遷移を管理（循環インポートを回避）
      initialRoute: AppConstants.routeHome,
      routes: {
        AppConstants.routeHome: (_) => const HomeScreen(),
        AppConstants.routeGame: (_) => const GameScreen(),
        AppConstants.routeResult: (_) => const ResultScreen(),
      },
    );
  }
}
