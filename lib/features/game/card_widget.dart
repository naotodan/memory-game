import 'dart:math';
import 'package:flutter/material.dart';
import 'game_controller.dart';
import '../../constants.dart';

/// メモリーゲームのカード1枚を表すウィジェット
/// フリップアニメーション＋正解時パーティクル演出を持つ
class CardWidget extends StatefulWidget {
  final CardModel card;
  final VoidCallback? onTap;

  const CardWidget({super.key, required this.card, this.onTap});

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with TickerProviderStateMixin {
  /// カードフリップ用コントローラー
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  /// 正解時パーティクル用コントローラー
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.flipDurationMs),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // 初期状態：裏向きなら即座に裏面の値をセット（アニメーションなし）
    if (!widget.card.isFaceUp && !widget.card.isMatched) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 表示状態の変化を検知してフリップアニメーションを実行
    final wasVisible = oldWidget.card.isFaceUp || oldWidget.card.isMatched;
    final isVisible = widget.card.isFaceUp || widget.card.isMatched;

    if (wasVisible != isVisible) {
      if (isVisible) {
        _flipController.reverse(); // 表向きへ
      } else {
        _flipController.forward(); // 裏向きへ
      }
    }

    // 正解になった瞬間にパーティクルを起動する
    if (!oldWidget.card.isMatched && widget.card.isMatched) {
      _particleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, _particleAnimation]),
        builder: (context, _) {
          final angle = _flipAnimation.value;
          // π/2 より小さければ表面、以上なら裏面
          final isFrontVisible = angle <= pi / 2;

          Widget face;
          if (isFrontVisible) {
            face = _buildFrontFace();
          } else {
            // 裏面は反転させて正立表示
            face = Transform(
              transform: Matrix4.rotationY(pi),
              alignment: Alignment.center,
              child: _buildBackFace(),
            );
          }

          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: Stack(
              children: [
                face,
                // 正解パーティクルオーバーレイ
                if (_particleAnimation.value > 0 && _particleAnimation.value < 1)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(_particleAnimation.value),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// カードの表面（数字を表示）
  Widget _buildFrontFace() {
    final Color bgColor;
    if (widget.card.isMatched) {
      // プレイヤーが正解したカード
      bgColor = Colors.green.shade500;
    } else if (widget.card.isError) {
      // ミスタップ中のカード
      bgColor = Colors.red.shade500;
    } else if (widget.card.isRevealed) {
      // ゲーム終了時に答え合わせとして開示されたカード
      bgColor = Colors.orange.shade400;
    } else {
      bgColor = Colors.blue.shade500;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Center(
        child: Text(
          '${widget.card.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }

  /// カードの裏面（？マークを表示）
  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.shade700,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.question_mark, color: Colors.white54, size: 32),
      ),
    );
  }
}

/// 正解時に輝く粒子が広がるパーティクルエフェクト
class _ParticlePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDistance = size.shortestSide * 0.55;

    const particleCount = 10;
    const colors = [
      Colors.yellow,
      Colors.amber,
      Colors.white,
      Colors.lightGreenAccent,
      Colors.cyanAccent,
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      // 奇数番は少し遅れて飛ぶ（奥行き感）
      final delay = (i % 2 == 0) ? 0.0 : 0.1;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

      final distance = maxDistance * t;
      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final radius = (5.0 * (1.0 - t * 0.6)).clamp(1.0, 5.0);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color =
              colors[i % colors.length].withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
