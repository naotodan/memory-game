import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_controller.dart';
import '../../constants.dart';
import '../../services/high_score_service.dart';

/// ホーム画面：タイトル・レベル選択・スタートボタンを表示する
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedLevel = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // アプリタイトル
                    Text(
                      'Memory Game',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '数字の順番を覚えてタップしよう！',
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                    ),
                    const SizedBox(height: 48),

                    // レベル選択
                    Text(
                      'レベル選択',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: AppConstants.memorizeSecondsByLevel.entries
                          .map((entry) {
                        final level = entry.key;
                        final memorizeSeconds = entry.value;
                        final isSelected = _selectedLevel == level;
                        final cols = AppConstants.columnsForLevel(level);
                        final rows = AppConstants.rowsForLevel(level);

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedLevel = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 90,
                              height: 110,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.amber
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.white30,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Lv $level',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$cols × $rows',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black54
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '暗記 $memorizeSeconds 秒',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black45
                                          : Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // ベストスコア
                                  _BestScoreText(
                                    level: level,
                                    isSelected: isSelected,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 56),

                    // スタートボタン
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 56, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 4,
                      ),
                      child: const Text('スタート'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ゲームを開始してゲーム画面へ遷移する
  void _startGame() {
    ref.read(gameControllerProvider.notifier).startGame(_selectedLevel);
    Navigator.of(context).pushNamed(AppConstants.routeGame);
  }
}

/// レベルカード内のベストスコア表示
class _BestScoreText extends ConsumerWidget {
  final int level;
  final bool isSelected;

  const _BestScoreText({required this.level, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highScoreAsync = ref.watch(highScoreProvider(level));

    return highScoreAsync.when(
      data: (score) {
        if (score == 0) {
          return Text(
            '---',
            style: TextStyle(
              color: isSelected ? Colors.black38 : Colors.white24,
              fontSize: 11,
            ),
          );
        }
        return Text(
          '$score pt',
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.lightBlueAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
      },
      loading: () => const SizedBox(height: 14),
      error: (_, _) => const SizedBox(height: 14),
    );
  }
}
