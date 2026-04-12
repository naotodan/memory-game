import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// レベルごとのハイスコアを SharedPreferences で永続化するサービス
class HighScoreService {
  static const String _keyPrefix = 'high_score_level_';

  /// 指定レベルのハイスコアを取得する
  Future<int> getHighScore(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$level') ?? 0;
  }

  /// スコアが現在のハイスコアを超えていれば更新し、true を返す
  Future<bool> tryUpdateHighScore(int level, int score) async {
    final current = await getHighScore(level);
    if (score > current) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_keyPrefix$level', score);
      return true;
    }
    return false;
  }
}

final highScoreServiceProvider = Provider<HighScoreService>((ref) {
  return HighScoreService();
});

/// レベルを引数にとるハイスコア取得プロバイダー
final highScoreProvider = FutureProvider.family<int, int>((ref, level) async {
  return ref.read(highScoreServiceProvider).getHighScore(level);
});
