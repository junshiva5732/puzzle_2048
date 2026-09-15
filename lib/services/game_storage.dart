import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game.dart';

/// 최고 점수와 진행 중인 게임을 기기에 저장한다.
class GameStorage {
  static const _kBest = 'best';
  static const _kGame = 'game';

  final SharedPreferences _prefs;
  GameStorage(this._prefs);

  static Future<GameStorage> create() async => GameStorage(await SharedPreferences.getInstance());

  int get best => _prefs.getInt(_kBest) ?? 0;
  Future<void> setBest(int v) => _prefs.setInt(_kBest, v);

  Game? loadGame() {
    final s = _prefs.getString(_kGame);
    if (s == null) return null;
    try {
      return Game.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGame(Game g) => _prefs.setString(_kGame, jsonEncode(g.toJson()));
  Future<void> clearGame() => _prefs.remove(_kGame);
}
