import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../config/game_config.dart';
import '../../domain/game_models.dart';
import '../../game/orbit_hop_game.dart';
import '../../l10n/app_strings.dart';
import '../widgets/neon_widgets.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final OrbitHopGame? game = controller.game;
    if (game == null) {
      return AppBackdrop(child: Center(child: NeonButton(label: strings.text('back_home'), onPressed: () => controller.navigateTo('home'), color: OrbitColors.cyan)));
    }
    return ValueListenableBuilder<RunHudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, RunHudState hud, Widget? child) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: game.launch,
              child: GameWidget<OrbitHopGame>(
                key: ValueKey<int>(controller.gameKey),
                game: game,
              ),
            ),
          ),
          _topHud(game, hud),
          if (hud.tutorialVisible && hud.phase == RunPhase.ready) _tutorialTip(),
          if (hud.phase == RunPhase.paused) _pausedOverlay(),
          if (hud.phase == RunPhase.gameOver) _gameOverOverlay(game, hud),
        ],
      ),
    );
  }

  Widget _topHud(OrbitHopGame game, RunHudState hud) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      tooltip: strings.text('paused'),
                      onPressed: game.phase == RunPhase.gameOver ? null : controller.pauseGame,
                      style: IconButton.styleFrom(backgroundColor: OrbitColors.panel.withValues(alpha: 0.83), foregroundColor: OrbitColors.cyan),
                      icon: const Icon(Icons.pause_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text('${hud.score}', style: const TextStyle(color: OrbitColors.text, fontSize: 26, fontWeight: FontWeight.w900, height: 0.95)),
                          const SizedBox(height: 3),
                          Text(strings.text('score'), style: const TextStyle(color: OrbitColors.muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                        ],
                      ),
                    ),
                    CurrencyPill(icon: Icons.circle, value: '${hud.runCoins}', color: OrbitColors.gold),
                    const SizedBox(width: 4),
                    if (hud.runGems > 0) CurrencyPill(icon: Icons.diamond_rounded, value: '${hud.runGems}', color: OrbitColors.violet),
                  ],
                ),
                if (hud.isFever) ...<Widget>[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF25172B).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(14), border: Border.all(color: OrbitColors.pink.withValues(alpha: 0.48))),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.local_fire_department_rounded, color: OrbitColors.pink, size: 14),
                        const SizedBox(width: 6),
                        Text('${strings.text('fever_banner')}  ×${hud.multiplier}', style: const TextStyle(color: OrbitColors.text, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(width: 9),
                        Expanded(child: ProgressMeter(value: hud.feverSeconds / 8, color: OrbitColors.pink, height: 5)),
                        const SizedBox(width: 7),
                        Text('${hud.feverSeconds.toStringAsFixed(1)}s', style: const TextStyle(color: OrbitColors.pink, fontSize: 9, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ] else if (hud.combo > 1) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(strings.text('perfect_combo', <String, Object>{'value': hud.combo}), style: const TextStyle(color: OrbitColors.gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
                if (hud.isDailyChallenge) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(strings.text('daily_challenge'), style: const TextStyle(color: OrbitColors.pink, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _tutorialTip() => Positioned(
        left: 20,
        right: 20,
        bottom: 24,
        child: IgnorePointer(
          child: SafeArea(
            top: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(color: OrbitColors.panel.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(20), border: Border.all(color: OrbitColors.cyan.withValues(alpha: 0.24))),
                child: Text(strings.text('tutorial_hint'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.text, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.25)),
              ),
            ),
          ),
        ),
      );

  Widget _pausedOverlay() => Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.64),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 370),
                  child: NeonPanel(
                    borderColor: OrbitColors.cyan,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.pause_circle_filled_rounded, color: OrbitColors.cyan, size: 54),
                        const SizedBox(height: 10),
                        Text(strings.text('paused'), style: const TextStyle(color: OrbitColors.text, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 7),
                        Text(strings.text('offline'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.muted, fontSize: 10)),
                        const SizedBox(height: 19),
                        SizedBox(width: double.infinity, child: NeonButton(label: strings.text('resume'), icon: Icons.play_arrow_rounded, onPressed: controller.resumeGame, color: OrbitColors.cyan)),
                        const SizedBox(height: 9),
                        SizedBox(width: double.infinity, child: NeonButton(label: strings.text('end_run'), icon: Icons.home_rounded, onPressed: controller.leaveGame, color: OrbitColors.violet, secondary: true)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _gameOverOverlay(OrbitHopGame game, RunHudState hud) => Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.72),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: NeonPanel(
                    borderColor: hud.finalized ? OrbitColors.violet : OrbitColors.pink,
                    padding: const EdgeInsets.all(19),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(hud.finalized ? Icons.auto_awesome_rounded : Icons.sentiment_dissatisfied_rounded, color: hud.finalized ? OrbitColors.violet : OrbitColors.pink, size: 40),
                        const SizedBox(height: 7),
                        Text(hud.finalized ? strings.text('run_complete') : strings.text('run_over'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.text, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
                        if (hud.deathLine.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(hud.deathLine, textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.45, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(child: _StatPill(title: strings.text('score'), value: '${hud.score}', color: OrbitColors.cyan)),
                            const SizedBox(width: 7),
                            Expanded(child: _StatPill(title: strings.text('run_coins'), value: '${hud.runCoins}', color: OrbitColors.gold)),
                            const SizedBox(width: 7),
                            Expanded(child: _StatPill(title: strings.text('combo'), value: '${game.maxCombo}', color: OrbitColors.violet)),
                          ],
                        ),
                        if (!hud.finalized) ...<Widget>[
                          const SizedBox(height: 14),
                          Text(strings.text('no_ads'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
                          const SizedBox(height: 10),
                          if (hud.reviveAvailable) ...<Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: NeonButton(
                                label: strings.text('revive'),
                                icon: Icons.favorite_rounded,
                                color: OrbitColors.pink,
                                onPressed: () {
                                  if (!controller.reviveWithRewardedAd()) controller.showMessage(strings.text('ads_unavailable'));
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(width: double.infinity, child: NeonButton(label: strings.text('end_run'), icon: Icons.check_rounded, color: OrbitColors.cyan, onPressed: game.finalizeRun)),
                        ] else ...<Widget>[
                          const SizedBox(height: 12),
                          if (hud.isDailyChallenge && hud.runSeconds >= GameConfig.dailyChallengeMinimumRunSeconds) ...<Widget>[
                            Text('${strings.text('daily_bonus')}  ·  +${GameConfig.dailyChallengeBonusCoins} ●  +${GameConfig.dailyChallengeBonusGems} ◆', style: const TextStyle(color: OrbitColors.pink, fontSize: 10, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 9),
                          ],
                          if (controller.lastRunResult != null && controller.save.lastDoubleCoinsRunNumber != controller.lastRunResult!.runNumber) ...<Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: NeonButton(
                                label: strings.text('double_coins'),
                                icon: Icons.ondemand_video_rounded,
                                color: OrbitColors.gold,
                                secondary: true,
                                onPressed: () {
                                  if (!controller.doubleCoinsWithRewardedAd()) controller.showMessage(strings.text('ads_unavailable'));
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (controller.starterOfferAvailable && !controller.save.starterBundleOwned) ...<Widget>[
                            SizedBox(width: double.infinity, child: NeonButton(label: strings.text('starter_bundle'), icon: Icons.redeem_rounded, color: OrbitColors.violet, secondary: true, onPressed: () => controller.navigateTo('shop'))),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: NeonButton(
                              label: hud.isDailyChallenge ? strings.text('back_home') : strings.text('play_again'),
                              icon: hud.isDailyChallenge ? Icons.home_rounded : Icons.replay_rounded,
                              color: OrbitColors.cyan,
                              onPressed: () {
                                final VoidCallback continueAfterAd = hud.isDailyChallenge
                                    ? () => controller.navigateTo('home')
                                    : controller.restartClassicRun;
                                final bool adShown = controller.showInterstitialAfterGameOver(onFinished: continueAfterAd);
                                if (!adShown) continueAfterAd();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: NeonButton(label: strings.text('share_score'), icon: Icons.share_rounded, color: OrbitColors.violet, secondary: true, onPressed: () => unawaited(controller.shareLastScore()))),
                          const SizedBox(height: 7),
                          TextButton.icon(onPressed: controller.leaveGame, icon: const Icon(Icons.home_rounded, size: 16), label: Text(strings.text('back_home')), style: TextButton.styleFrom(foregroundColor: OrbitColors.muted)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13), border: Border.all(color: color.withValues(alpha: 0.18))),
        child: Column(
          children: <Widget>[
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.muted, fontSize: 7, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
