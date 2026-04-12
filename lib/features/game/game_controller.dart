import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants.dart';

/// ゲームのフェーズ
enum GamePhase { memorizing, playing, result }

/// カード1枚のデータモデル
@immutable
class CardModel {
  final int id;
  final int number;
  final bool isFaceUp;
  final bool isMatched;
  final bool isError;

  /// ゲーム終了時に答え合わせとして開示されたカード
  final bool isRevealed;

  const CardModel({
    required this.id,
    required this.number,
    this.isFaceUp = true,
    this.isMatched = false,
    this.isError = false,
    this.isRevealed = false,
  });

  CardModel copyWith({
    bool? isFaceUp,
    bool? isMatched,
    bool? isError,
    bool? isRevealed,
  }) =>
      CardModel(
        id: id,
        number: number,
        isFaceUp: isFaceUp ?? this.isFaceUp,
        isMatched: isMatched ?? this.isMatched,
        isError: isError ?? this.isError,
        isRevealed: isRevealed ?? this.isRevealed,
      );
}

/// ゲーム全体の状態
@immutable
class GameState {
  final GamePhase phase;
  final List<CardModel> cards;

  /// 次にタップすべき数字
  final int currentTarget;
  final int level;

  /// 累積スコア（タップのたびにインクリメント）
  final int score;
  final int elapsedSeconds;

  /// 暗記フェーズの残り秒数
  final int memorizeCountdown;

  /// ミス回数
  final int missCount;

  /// 残りライフ数
  final int lives;

  /// クリア成功かどうか（false = ライフ切れ or タイムアップでゲームオーバー）
  final bool isClear;

  /// プレイフェーズの残り制限時間（秒）
  final int remainingSeconds;

  /// 現在のコンボ数（連続正解数）
  final int combo;

  /// ゲーム中の最大コンボ数
  final int maxCombo;

  /// タップするべき順番のシーケンス（Lv1: 昇順、Lv2/Lv3: ランダム）
  final List<int> targetSequence;

  /// targetSequence の現在位置
  final int targetSequenceIndex;

  /// ヒントボタンを使用済みかどうか
  final bool hintUsed;

  /// ヒント表示中（全カードが一時的に表向き）かどうか
  final bool hintActive;

  const GameState({
    this.phase = GamePhase.memorizing,
    this.cards = const [],
    this.currentTarget = 1,
    this.level = 1,
    this.score = 0,
    this.elapsedSeconds = 0,
    this.memorizeCountdown = 5,
    this.missCount = 0,
    this.lives = AppConstants.initialLives,
    this.isClear = false,
    this.remainingSeconds = 60,
    this.combo = 0,
    this.maxCombo = 0,
    this.targetSequence = const <int>[],
    this.targetSequenceIndex = 0,
    this.hintUsed = false,
    this.hintActive = false,
  });

  GameState copyWith({
    GamePhase? phase,
    List<CardModel>? cards,
    int? currentTarget,
    int? level,
    int? score,
    int? elapsedSeconds,
    int? memorizeCountdown,
    int? missCount,
    int? lives,
    bool? isClear,
    int? remainingSeconds,
    int? combo,
    int? maxCombo,
    List<int>? targetSequence,
    int? targetSequenceIndex,
    bool? hintUsed,
    bool? hintActive,
  }) =>
      GameState(
        phase: phase ?? this.phase,
        cards: cards ?? this.cards,
        currentTarget: currentTarget ?? this.currentTarget,
        level: level ?? this.level,
        score: score ?? this.score,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        memorizeCountdown: memorizeCountdown ?? this.memorizeCountdown,
        missCount: missCount ?? this.missCount,
        lives: lives ?? this.lives,
        isClear: isClear ?? this.isClear,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        combo: combo ?? this.combo,
        maxCombo: maxCombo ?? this.maxCombo,
        targetSequence: targetSequence ?? this.targetSequence,
        targetSequenceIndex: targetSequenceIndex ?? this.targetSequenceIndex,
        hintUsed: hintUsed ?? this.hintUsed,
        hintActive: hintActive ?? this.hintActive,
      );
}

/// ゲームのロジックを管理するコントローラー
class GameController extends StateNotifier<GameState> {
  Timer? _memorizeTimer;
  Timer? _playTimer;

  /// Level 3 専用：カード位置スワップタイマー
  Timer? _swapTimer;

  GameController() : super(const GameState());

  /// 指定レベルでゲームを開始する
  void startGame(int level) {
    _cancelTimers();

    final memorizeSeconds =
        AppConstants.memorizeSecondsByLevel[level] ?? AppConstants.memorizeSecondsByLevel[1]!;
    final timeLimit =
        AppConstants.timeLimitSecondsByLevel[level] ?? AppConstants.timeLimitSecondsByLevel[1]!;
    final totalCards = AppConstants.totalCardsForLevel(level);

    // グリッドに配置する数字（シャッフル）
    final numbers = List.generate(totalCards, (i) => i + 1);
    numbers.shuffle();
    final cards = numbers
        .asMap()
        .entries
        .map((e) => CardModel(id: e.key, number: e.value, isFaceUp: true))
        .toList();

    // タップシーケンス：Lv1 は昇順、Lv2/Lv3 はランダム順
    final sequence = List.generate(totalCards, (i) => i + 1);
    if (level >= 2) sequence.shuffle();

    state = GameState(
      phase: GamePhase.memorizing,
      cards: cards,
      currentTarget: sequence[0],
      level: level,
      score: 0,
      elapsedSeconds: 0,
      memorizeCountdown: memorizeSeconds,
      missCount: 0,
      lives: AppConstants.initialLives,
      isClear: false,
      remainingSeconds: timeLimit,
      combo: 0,
      maxCombo: 0,
      targetSequence: sequence,
      targetSequenceIndex: 0,
    );

    _startMemorizeTimer(memorizeSeconds);
  }

  /// カードをタップした時の処理
  void tapCard(int cardId) {
    if (state.phase != GamePhase.playing) return;

    final card = state.cards.firstWhere((c) => c.id == cardId);
    if (card.isMatched) return;

    if (card.number == state.currentTarget) {
      // ────────────────────────────
      // 正解：コンボ・スコアをインクリメント
      // ────────────────────────────
      final newCombo = state.combo + 1;
      final newMaxCombo = max(newCombo, state.maxCombo);
      final comboMultiplier =
          1.0 + ((newCombo - 1) * AppConstants.comboMultiplierStep);
      final levelMultiplier =
          AppConstants.levelScoreMultiplier[state.level] ?? 1.0;
      final cardPoints =
          (AppConstants.baseScorePerCard * levelMultiplier * comboMultiplier)
              .round();

      final updatedCards = state.cards
          .map((c) => c.id == cardId
              ? c.copyWith(isFaceUp: true, isMatched: true, isError: false)
              : c)
          .toList();

      final newSequenceIndex = state.targetSequenceIndex + 1;
      final allDone = newSequenceIndex >= state.targetSequence.length;

      if (allDone) {
        // 全カードクリア → タイムボーナスを加算してリザルトへ
        _cancelTimers();
        final timeBonus =
            state.remainingSeconds * AppConstants.timeBonusMultiplier;
        final finalScore = state.score + cardPoints + timeBonus;
        state = state.copyWith(
          cards: updatedCards,
          targetSequenceIndex: newSequenceIndex,
          phase: GamePhase.result,
          score: finalScore,
          combo: newCombo,
          maxCombo: newMaxCombo,
          isClear: true,
        );
      } else {
        final nextTarget = state.targetSequence[newSequenceIndex];
        state = state.copyWith(
          cards: updatedCards,
          currentTarget: nextTarget,
          targetSequenceIndex: newSequenceIndex,
          score: state.score + cardPoints,
          combo: newCombo,
          maxCombo: newMaxCombo,
        );
      }
    } else {
      // ────────────────────────────
      // 不正解：コンボリセット・ライフを1減らしてエラー表示
      // ────────────────────────────
      final newLives = state.lives - 1;
      final cardsWithError = state.cards
          .map((c) => c.id == cardId
              ? c.copyWith(isError: true, isFaceUp: true)
              : c)
          .toList();

      if (newLives <= 0) {
        // ライフ切れ → 全カード開示してゲームオーバー
        _cancelTimers();
        final revealedCards = _revealUnmatchedCards(cardsWithError);
        state = state.copyWith(
          cards: revealedCards,
          missCount: state.missCount + 1,
          lives: 0,
          combo: 0,
          phase: GamePhase.result,
          isClear: false,
        );
      } else {
        // ライフ残あり：エラー表示後にカードを裏に戻す
        state = state.copyWith(
          cards: cardsWithError,
          missCount: state.missCount + 1,
          lives: newLives,
          combo: 0,
        );

        Future.delayed(
          const Duration(milliseconds: AppConstants.errorDisplayMs),
          () {
            if (!mounted) return;
            final resetCards = state.cards
                .map((c) => c.id == cardId
                    ? c.copyWith(isError: false, isFaceUp: false)
                    : c)
                .toList();
            state = state.copyWith(cards: resetCards);
          },
        );
      }
    }
  }

  /// 暗記フェーズのカウントダウンタイマーを開始する
  void _startMemorizeTimer(int seconds) {
    int countdown = seconds;
    _memorizeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown <= 0) {
        timer.cancel();
        _flipAllCardsDown();
      } else {
        state = state.copyWith(memorizeCountdown: countdown);
      }
    });
  }

  /// 全カードを裏向きにしてプレイフェーズへ移行する
  void _flipAllCardsDown() {
    final cards = state.cards.map((c) => c.copyWith(isFaceUp: false)).toList();
    state = state.copyWith(
      phase: GamePhase.playing,
      cards: cards,
      memorizeCountdown: 0,
    );
    _startPlayTimer();
    _startSwapTimer(); // Lv3 のみ有効
  }

  /// プレイ中のタイマーを開始する（経過時間カウントアップ＋残り時間カウントダウン）
  void _startPlayTimer() {
    _playTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newRemaining = state.remainingSeconds - 1;
      if (newRemaining <= 0) {
        // タイムアップ → 全カード開示してゲームオーバー
        _cancelTimers();
        final revealedCards = _revealUnmatchedCards(state.cards);
        state = state.copyWith(
          cards: revealedCards,
          remainingSeconds: 0,
          elapsedSeconds: state.elapsedSeconds + 1,
          combo: 0,
          phase: GamePhase.result,
          isClear: false,
        );
      } else {
        state = state.copyWith(
          remainingSeconds: newRemaining,
          elapsedSeconds: state.elapsedSeconds + 1,
        );
      }
    });
  }

  /// Level 3 専用：一定間隔でランダムな未一致カード2枚の位置を入れ替える
  void _startSwapTimer() {
    if (state.level < 3) return;
    _swapTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.cardSwapIntervalMs),
      (_) {
        if (state.phase != GamePhase.playing) return;
        _swapTwoRandomUnmatchedCards();
      },
    );
  }

  /// ヒントボタン：未一致カードを3秒間だけ表向きにする（1回限り）
  void useHint() {
    if (state.hintUsed || state.phase != GamePhase.playing) return;

    final revealedCards = state.cards.map((c) {
      if (!c.isMatched) return c.copyWith(isFaceUp: true);
      return c;
    }).toList();

    state = state.copyWith(
      cards: revealedCards,
      hintUsed: true,
      hintActive: true,
    );

    // 3秒後に裏向きに戻す
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || state.phase != GamePhase.playing) return;
      final hiddenCards = state.cards.map((c) {
        if (!c.isMatched) return c.copyWith(isFaceUp: false);
        return c;
      }).toList();
      state = state.copyWith(cards: hiddenCards, hintActive: false);
    });
  }

  /// 未一致カードをランダムに2枚選んでリスト上の位置を入れ替える
  void _swapTwoRandomUnmatchedCards() {
    final indices = state.cards
        .asMap()
        .entries
        .where((e) => !e.value.isMatched)
        .map((e) => e.key)
        .toList();

    if (indices.length < 2) return;

    indices.shuffle();
    final i = indices[0];
    final j = indices[1];

    final newCards = List<CardModel>.from(state.cards);
    final temp = newCards[i];
    newCards[i] = newCards[j];
    newCards[j] = temp;

    state = state.copyWith(cards: newCards);
  }

  /// 未一致カードをすべて表向きに開示する（ゲーム終了時の答え合わせ）
  List<CardModel> _revealUnmatchedCards(List<CardModel> cards) {
    return cards.map((c) {
      if (!c.isMatched) {
        return c.copyWith(isFaceUp: true, isRevealed: true, isError: false);
      }
      return c;
    }).toList();
  }

  void _cancelTimers() {
    _memorizeTimer?.cancel();
    _playTimer?.cancel();
    _swapTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}

/// ゲームコントローラーのプロバイダー
final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});
