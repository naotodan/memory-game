import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';
import 'card_widget.dart';
import '../../constants.dart';
import '../../services/sound_service.dart';

/// ゲーム画面：カードグリッドの表示とゲーム操作を担当する
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  /// ライフ減少時の赤フラッシュアニメーション
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  /// 「ライフ -1」オーバーレイの表示フラグ
  bool _showLifeLostText = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flashAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  /// ライフ減少時のフィードバック
  void _triggerLifeLost() {
    HapticFeedback.heavyImpact();
    ref.read(soundServiceProvider).playMiss();
    _flashController.forward(from: 0.0);
    setState(() => _showLifeLostText = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showLifeLostText = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final sound = ref.read(soundServiceProvider);

    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      // リザルト遷移（フリップ完了を待つ）
      if (previous?.phase != GamePhase.result &&
          next.phase == GamePhase.result) {
        if (next.isClear) sound.playClear();
        final args = {
          'score': next.score,
          'elapsedSeconds': next.elapsedSeconds,
          'level': next.level,
          'missCount': next.missCount,
          'isClear': next.isClear,
          'maxCombo': next.maxCombo,
        };
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(
              AppConstants.routeResult,
              arguments: args,
            );
          }
        });
      }

      // ライフ減少
      if (previous != null && next.lives < previous.lives) {
        _triggerLifeLost();
      }

      // 正解タップ（target が進んだ = 正解）
      if (previous != null &&
          next.phase == GamePhase.playing &&
          next.currentTarget != previous.currentTarget) {
        if (next.combo >= 3) {
          HapticFeedback.mediumImpact();
          sound.playCombo();
        } else {
          HapticFeedback.lightImpact();
          sound.playCorrect();
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.indigo.shade900,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'ゲームを終了',
            ),
            title: Text(
              'Level ${gameState.level}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              // ライフ表示
              if (gameState.phase == GamePhase.playing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: List.generate(
                      AppConstants.initialLives,
                      (i) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          key: ValueKey('life_${i}_${i < gameState.lives}'),
                          i < gameState.lives
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: i < gameState.lives
                              ? Colors.red
                              : Colors.white30,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              // 残り時間
              if (gameState.phase == GamePhase.playing)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _RemainingTimeText(
                        remaining: gameState.remainingSeconds),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _StatusBar(state: gameState),
                if (gameState.phase == GamePhase.playing)
                  _TimeProgressBar(state: gameState),
                const SizedBox(height: 4),
                if (gameState.phase == GamePhase.playing && gameState.combo >= 2)
                  _ComboBadge(combo: gameState.combo),
                const SizedBox(height: 4),
                Expanded(
                  child: _CardGrid(state: gameState, ref: ref),
                ),
                // ヒントボタン
                if (gameState.phase == GamePhase.playing)
                  _HintButton(state: gameState, ref: ref),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ライフ減少フラッシュ
        AnimatedBuilder(
          animation: _flashAnimation,
          builder: (context, _) => IgnorePointer(
            child: Container(
              color: Colors.red.withValues(alpha: _flashAnimation.value),
            ),
          ),
        ),

        // 「ライフ -1」テキスト
        if (_showLifeLostText)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'ライフ -1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ヒントボタン：1回限り全カードを3秒間表示する
class _HintButton extends StatelessWidget {
  final GameState state;
  final WidgetRef ref;

  const _HintButton({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final used = state.hintUsed;
    final active = state.hintActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: used
              ? null
              : () {
                  ref.read(soundServiceProvider).playHint();
                  ref.read(gameControllerProvider.notifier).useHint();
                },
          icon: Icon(
            active ? Icons.visibility : Icons.lightbulb_outline,
            size: 18,
          ),
          label: Text(
            used
                ? (active ? '確認中… (3秒)' : 'ヒント使用済み')
                : 'ヒント（全部見る）',
            style: const TextStyle(fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: used ? Colors.white24 : Colors.amber,
            side: BorderSide(
              color: used ? Colors.white12 : Colors.amber.withValues(alpha: 0.7),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ),
    );
  }
}

/// コンボバッジ
class _ComboBadge extends StatelessWidget {
  final int combo;

  const _ComboBadge({required this.combo});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    if (combo >= 8) {
      badgeColor = Colors.deepOrange;
    } else if (combo >= 5) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.amber.shade700;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(combo),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: badgeColor.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1),
          ],
        ),
        child: Text(
          'COMBO × $combo',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// 残り時間テキスト（残り時間に応じて色変化）
class _RemainingTimeText extends StatelessWidget {
  final int remaining;

  const _RemainingTimeText({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final bool bold;
    if (remaining > 20) {
      color = Colors.white70;
      bold = false;
    } else if (remaining > 10) {
      color = Colors.amber;
      bold = true;
    } else {
      color = Colors.red;
      bold = true;
    }
    return Text(
      '${remaining}s',
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

/// 残り時間プログレスバー
class _TimeProgressBar extends StatelessWidget {
  final GameState state;

  const _TimeProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final timeLimit = AppConstants.timeLimitSecondsByLevel[state.level] ??
        AppConstants.timeLimitSecondsByLevel[1]!;
    final progress =
        (state.remainingSeconds / timeLimit).clamp(0.0, 1.0);

    final Color barColor;
    if (progress > 0.5) {
      barColor = Colors.greenAccent;
    } else if (progress > 0.25) {
      barColor = Colors.amber;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ),
    );
  }
}

/// ステータスバー
class _StatusBar extends StatelessWidget {
  final GameState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final (String message, Color color) = switch (state.phase) {
      GamePhase.memorizing => (
          '${state.memorizeCountdown}秒で隠れます！しっかり覚えてください',
          Colors.amber
        ),
      GamePhase.playing => (
          '「 ${state.currentTarget} 」をタップ！',
          Colors.lightBlueAccent
        ),
      GamePhase.result => ('クリア！', Colors.greenAccent),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// カードグリッド
/// Level 3 プレイ中は AnimatedPositioned でカードが滑らかに移動する
class _CardGrid extends StatelessWidget {
  final GameState state;
  final WidgetRef ref;

  const _CardGrid({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cols = AppConstants.columnsForLevel(state.level);
    final rows = AppConstants.rowsForLevel(state.level);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const padding = 16.0;

        final maxCardW =
            (constraints.maxWidth - padding * 2 - spacing * (cols - 1)) / cols;
        final maxCardH =
            (constraints.maxHeight - spacing * (rows - 1)) / rows;
        final cardSize = maxCardW < maxCardH ? maxCardW : maxCardH;

        final gridW = cardSize * cols + spacing * (cols - 1) + padding * 2;
        final gridH = cardSize * rows + spacing * (rows - 1);

        final useAnimated =
            state.level == 3 && state.phase == GamePhase.playing;

        return Center(
          child: SizedBox(
            width: gridW,
            height: gridH,
            child: useAnimated
                ? _buildAnimatedGrid(cols, cardSize, spacing, padding)
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: padding),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: state.cards.length,
                      itemBuilder: (context, index) {
                        final card = state.cards[index];
                        return CardWidget(
                          card: card,
                          onTap: state.phase == GamePhase.playing &&
                                  !card.isMatched
                              ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .tapCard(card.id)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Level 3 用アニメーションレイアウト
  Widget _buildAnimatedGrid(
      int cols, double cardSize, double spacing, double padding) {
    return Stack(
      children: state.cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        final col = index % cols;
        final row = index ~/ cols;
        final x = padding + col * (cardSize + spacing);
        final y = row * (cardSize + spacing);

        return AnimatedPositioned(
          key: ValueKey(card.id),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          left: x,
          top: y,
          width: cardSize,
          height: cardSize,
          child: CardWidget(
            card: card,
            onTap: !card.isMatched
                ? () => ref
                    .read(gameControllerProvider.notifier)
                    .tapCard(card.id)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
