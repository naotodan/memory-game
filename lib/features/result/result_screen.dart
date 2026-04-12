import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/game_controller.dart';
import '../../constants.dart';
import '../../services/high_score_service.dart';

/// リザルト画面：ゲーム終了後のスコア・ランク・ハイスコアを表示する
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  /// スコアのカウントアップ用アニメーション
  late AnimationController _scoreController;
  late Animation<int> _scoreAnimation;

  bool _isNewRecord = false;
  bool _scoreChecked = false;

  late int _finalScore;
  late int _level;
  late bool _isClear;
  late int _elapsedSeconds;
  late int _missCount;
  late int _maxCombo;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scoreChecked) return;
    _scoreChecked = true;

    // ゲーム画面から渡された結果データを取得
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _finalScore = args['score'] as int;
    _level = args['level'] as int;
    _isClear = args['isClear'] as bool;
    _elapsedSeconds = args['elapsedSeconds'] as int;
    _missCount = args['missCount'] as int;
    _maxCombo = args['maxCombo'] as int? ?? 0;

    // スコアのカウントアップアニメーションを設定
    _scoreAnimation = IntTween(begin: 0, end: _finalScore).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    );
    _scoreController.forward();

    // ハイスコアの更新チェック
    ref
        .read(highScoreServiceProvider)
        .tryUpdateHighScore(_level, _finalScore)
        .then((isNew) {
      if (mounted) {
        setState(() => _isNewRecord = isNew);
        // ハイスコアプロバイダーを無効化して再取得させる
        ref.invalidate(highScoreProvider(_level));
      }
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = AppConstants.rankForScore(_finalScore, _level);
    final highScoreAsync = ref.watch(highScoreProvider(_level));

    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // クリア or ゲームオーバーアイコン
                Icon(
                  _isClear ? Icons.emoji_events : Icons.heart_broken,
                  color: _isClear ? Colors.amber : Colors.red,
                  size: 72,
                ),
                const SizedBox(height: 12),
                Text(
                  _isClear ? 'ゲームクリア！' : 'ゲームオーバー',
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _isClear
                                ? Colors.white
                                : Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 20),

                // ランクバッジ
                _RankBadge(rank: rank),
                const SizedBox(height: 20),

                // スコア（カウントアップ）
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, _) {
                    return Column(
                      children: [
                        Text(
                          '${_scoreAnimation.value}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'pts',
                          style: TextStyle(
                            color: Colors.amber.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // NEW RECORD バッジ
                if (_isNewRecord)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '★ NEW RECORD ★',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // スコア詳細カード
                _ResultCard(
                  level: _level,
                  elapsedSeconds: _elapsedSeconds,
                  missCount: _missCount,
                  maxCombo: _maxCombo,
                  highScore: highScoreAsync.valueOrNull ?? 0,
                ),
                const SizedBox(height: 36),

                // 操作ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppConstants.routeHome,
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('ホームへ',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .startGame(_level);
                        Navigator.of(context).pushReplacementNamed(
                          AppConstants.routeGame,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('もう一度'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ランク文字を大きく表示するバッジ
class _RankBadge extends StatelessWidget {
  final String rank;

  const _RankBadge({required this.rank});

  static const Map<String, Color> _rankColors = {
    'S': Colors.amber,
    'A': Colors.orange,
    'B': Colors.lightBlue,
    'C': Colors.lightGreen,
    'D': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final color = _rankColors[rank] ?? Colors.grey;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            color: color,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// スコア詳細・ハイスコアを表示するカードウィジェット
class _ResultCard extends StatelessWidget {
  final int level;
  final int elapsedSeconds;
  final int missCount;
  final int maxCombo;
  final int highScore;

  const _ResultCard({
    required this.level,
    required this.elapsedSeconds,
    required this.missCount,
    required this.maxCombo,
    required this.highScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          _buildRow('レベル', 'Lv $level  '
              '(${AppConstants.columnsForLevel(level)}×${AppConstants.rowsForLevel(level)})'),
          const Divider(color: Colors.white24),
          _buildRow('プレイ時間', '$elapsedSeconds 秒'),
          const Divider(color: Colors.white24),
          _buildRow('ミス回数', '$missCount 回'),
          const Divider(color: Colors.white24),
          _buildRow('最大コンボ', '$maxCombo コンボ',
              valueColor: maxCombo >= 5 ? Colors.orange : Colors.white),
          const Divider(color: Colors.white24),
          _buildRow(
            'ベストスコア',
            '$highScore',
            valueColor: Colors.lightBlueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
