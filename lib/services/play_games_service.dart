import 'dart:io';

import 'package:games_services/games_services.dart';

import '../config/game_config.dart';

/// Optional Google Play Games bridge. All platform/service failures are quiet;
/// local best scores remain available when sign-in is skipped or unavailable.
class PlayGamesService {
  bool _signedIn = false;

  bool get signedIn => _signedIn;

  Future<bool> signIn() async {
    if (!Platform.isAndroid) return false;
    try {
      await GameAuth.signIn();
      _signedIn = await GameAuth.isSignedIn;
    } catch (_) {
      _signedIn = false;
    }
    return _signedIn;
  }

  Future<bool> submitScore({required int score, required bool daily}) async {
    if (!Platform.isAndroid || !_signedIn || score < 0) return false;
    final String leaderboardId = daily
        ? GameConfig.playDailyLeaderboardId
        : GameConfig.playBestScoreLeaderboardId;
    if (leaderboardId.isEmpty) return false;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          iOSLeaderboardID: '',
          value: score,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showLeaderboard({required bool daily}) async {
    if (!Platform.isAndroid || !_signedIn) return false;
    final String leaderboardId = daily
        ? GameConfig.playDailyLeaderboardId
        : GameConfig.playBestScoreLeaderboardId;
    if (leaderboardId.isEmpty) return false;
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: leaderboardId,
        iOSLeaderboardID: '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
