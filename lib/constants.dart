/// アプリ全体で使用する定数
class AppConstants {
  // ----------------------------------------------------------------
  // グリッドサイズ（レベル別）
  // ----------------------------------------------------------------

  /// レベル別の列数（全レベル 3×4=12枚 に統一）
  static const Map<int, int> gridColumnsByLevel = {
    1: 3,
    2: 3,
    3: 3,
  };

  /// レベル別の行数
  static const Map<int, int> gridRowsByLevel = {
    1: 4,
    2: 4,
    3: 4,
  };

  /// 指定レベルの列数を返す
  static int columnsForLevel(int level) =>
      gridColumnsByLevel[level] ?? gridColumnsByLevel[1]!;

  /// 指定レベルの行数を返す
  static int rowsForLevel(int level) =>
      gridRowsByLevel[level] ?? gridRowsByLevel[1]!;

  /// 指定レベルのカード総数を返す
  static int totalCardsForLevel(int level) =>
      columnsForLevel(level) * rowsForLevel(level);

  // ----------------------------------------------------------------
  // ゲームタイミング
  // ----------------------------------------------------------------

  /// レベル別の暗記時間（秒）
  static const Map<int, int> memorizeSecondsByLevel = {
    1: 10, // 12枚
    2: 10, // 20枚
    3: 10, // 24枚
  };

  /// レベル別のプレイ制限時間（秒）
  static const Map<int, int> timeLimitSecondsByLevel = {
    1: 60,
    2: 80,
    3: 100,
  };

  // ----------------------------------------------------------------
  // スコア計算
  // ----------------------------------------------------------------

  /// カード1枚あたりの基本スコア
  static const int baseScorePerCard = 100;

  /// タイムボーナスの乗数（残り秒数 × この値）
  static const int timeBonusMultiplier = 10;

  /// レベル別のスコア倍率
  static const Map<int, double> levelScoreMultiplier = {
    1: 1.0,
    2: 1.5,
    3: 2.0,
  };

  /// コンボ1回ごとの倍率加算量（combo=1→1.0x, combo=2→1.1x, combo=5→1.4x）
  static const double comboMultiplierStep = 0.1;

  // ----------------------------------------------------------------
  // ランク閾値（レベル別：[S, A, B, C] 以下はD）
  // ----------------------------------------------------------------

  static const Map<int, List<int>> rankThresholdsByLevel = {
    1: [2200, 1500, 900,  400],
    2: [4000, 2800, 1600, 700],
    3: [7000, 5000, 3000, 1300],
  };

  /// スコアとレベルからランク文字列を返す
  static String rankForScore(int score, int level) {
    final t = rankThresholdsByLevel[level] ?? rankThresholdsByLevel[1]!;
    if (score >= t[0]) return 'S';
    if (score >= t[1]) return 'A';
    if (score >= t[2]) return 'B';
    if (score >= t[3]) return 'C';
    return 'D';
  }

  // ----------------------------------------------------------------
  // ライフ・アニメーション
  // ----------------------------------------------------------------

  /// ゲーム開始時のライフ数
  static const int initialLives = 3;

  /// エラー表示後にカードを裏返すまでの時間（ミリ秒）
  static const int errorDisplayMs = 1000;

  /// カードフリップアニメーションの時間（ミリ秒）
  static const int flipDurationMs = 400;

  /// Level 3 でカードが位置を入れ替える間隔（ミリ秒）
  static const int cardSwapIntervalMs = 2000;

  // ----------------------------------------------------------------
  // ルート名
  // ----------------------------------------------------------------

  /// ルート名：ホーム
  static const String routeHome = '/';

  /// ルート名：ゲーム
  static const String routeGame = '/game';

  /// ルート名：リザルト
  static const String routeResult = '/result';
}
