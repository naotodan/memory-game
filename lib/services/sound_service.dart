import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ゲーム効果音を管理するサービス
/// audioplayers を使用してアセット内の WAV ファイルを再生する
class SoundService {
  // 各音声ごとに独立したプレイヤーを持つことで同時再生に対応する
  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _missPlayer    = AudioPlayer();
  final AudioPlayer _clearPlayer   = AudioPlayer();
  final AudioPlayer _comboPlayer   = AudioPlayer();
  final AudioPlayer _hintPlayer    = AudioPlayer();

  Future<void> playCorrect() => _play(_correctPlayer, 'sounds/correct.wav');
  Future<void> playMiss()    => _play(_missPlayer,    'sounds/miss.wav');
  Future<void> playClear()   => _play(_clearPlayer,   'sounds/clear.wav');
  Future<void> playCombo()   => _play(_comboPlayer,   'sounds/combo.wav');
  Future<void> playHint()    => _play(_hintPlayer,    'sounds/hint.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.play(AssetSource(asset));
    } catch (_) {
      // ファイルが見つからない場合などは無視
    }
  }

  void dispose() {
    _correctPlayer.dispose();
    _missPlayer.dispose();
    _clearPlayer.dispose();
    _comboPlayer.dispose();
    _hintPlayer.dispose();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
