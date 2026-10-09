import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../config/game_config.dart';
import '../../domain/economy.dart';
import '../../l10n/app_strings.dart';
import '../widgets/neon_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final save = controller.save;
    final LevelProgress level = LevelRules.progressFor(save.experience);
    return AppBackdrop(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              sliver: SliverList.list(
                children: <Widget>[
                  _homeHeader(context, level),
                  const SizedBox(height: 18),
                  _heroCard(context),
                  const SizedBox(height: 15),
                  NeonButton(
                    label: strings.text('play'),
                    icon: Icons.play_arrow_rounded,
                    color: OrbitColors.cyan,
                    onPressed: () => controller.startGame(),
                  ),
                  const SizedBox(height: 13),
                  _dailyChallenge(context),
                  const SizedBox(height: 13),
                  _dailyRewardCard(context),
                  const SizedBox(height: 13),
                  _freeChestCard(context),
                  const SizedBox(height: 20),
                  SectionTitle(strings.text('missions'), trailing: _seeAll(() => controller.navigateTo('missions'))),
                  const SizedBox(height: 10),
                  _missionsSummary(),
                  const SizedBox(height: 20),
                  SectionTitle(strings.text('shop')),
                  const SizedBox(height: 10),
                  _shortcuts(context),
                  const SizedBox(height: 18),
                  _leaderboardCard(context),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${strings.text('ages')}  ·  ${strings.text('no_banners')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeHeader(BuildContext context, LevelProgress level) {
    final int toNext = (level.nextLevelXp - level.currentXp).clamp(0, 999999).toInt();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: OrbitColors.cyan.withValues(alpha: 0.11),
            shape: BoxShape.circle,
            border: Border.all(color: OrbitColors.cyan.withValues(alpha: 0.48)),
            boxShadow: <BoxShadow>[BoxShadow(color: OrbitColors.cyan.withValues(alpha: 0.12), blurRadius: 20)],
          ),
          child: const Icon(Icons.blur_circular_rounded, color: OrbitColors.cyan, size: 29),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.text('app_name'), style: const TextStyle(color: OrbitColors.text, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
              Text(strings.text('tagline'), style: const TextStyle(color: OrbitColors.muted, fontSize: 11)),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  Text(strings.text('level', <String, Object>{'value': level.level}), style: const TextStyle(color: OrbitColors.cyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(width: 7),
                  Expanded(child: ProgressMeter(value: level.fraction, height: 5)),
                  const SizedBox(width: 7),
                  Text(strings.text('to_next_level', <String, Object>{'value': toNext}), style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        IconButton.filledTonal(
          tooltip: strings.text('settings'),
          onPressed: () => controller.navigateTo('settings'),
          style: IconButton.styleFrom(backgroundColor: OrbitColors.panelLight, foregroundColor: OrbitColors.text),
          icon: const Icon(Icons.settings_rounded, size: 19),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context) {
    return NeonPanel(
      padding: EdgeInsets.zero,
      borderColor: OrbitColors.violet,
      child: SizedBox(
        height: 164,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _OrbitArtworkPainter())),
            Positioned(
              left: 15,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.text('classic_best'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('${controller.save.bestScore}', style: const TextStyle(color: OrbitColors.text, fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('${controller.save.totalRuns} ${strings.text('run_count').toLowerCase()}', style: const TextStyle(color: OrbitColors.muted, fontSize: 10)),
                ],
              ),
            ),
            Positioned(
              right: 13,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  CurrencyPill(icon: Icons.circle, value: _compact(controller.save.coins), color: OrbitColors.gold),
                  const SizedBox(height: 7),
                  CurrencyPill(icon: Icons.diamond_rounded, value: _compact(controller.save.gems), color: OrbitColors.violet),
                ],
              ),
            ),
            Positioned(
              left: 23,
              bottom: 13,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.local_fire_department_rounded, color: OrbitColors.gold, size: 15),
                  const SizedBox(width: 4),
                  Text(strings.text('streak', <String, Object>{'value': controller.save.dailyStreak}), style: const TextStyle(color: OrbitColors.gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 13,
              child: Text(
                '${strings.text('total_planets')}: ${controller.save.lifetimePlanets}',
                style: const TextStyle(color: OrbitColors.muted, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyChallenge(BuildContext context) {
    final bool available = controller.dailyChallengeAvailable;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: available ? () => controller.startGame(dailyChallenge: true) : null,
        borderRadius: BorderRadius.circular(20),
        child: NeonPanel(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          borderColor: available ? OrbitColors.pink : null,
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: OrbitColors.pink.withValues(alpha: 0.13), shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded, color: OrbitColors.pink, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.text('daily_challenge'), style: const TextStyle(color: OrbitColors.text, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.7)),
                    const SizedBox(height: 3),
                    Text(
                      available ? strings.text('play_once') : strings.text('played_today'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(available ? Icons.arrow_forward_ios_rounded : Icons.check_circle_rounded, color: available ? OrbitColors.pink : OrbitColors.muted, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyRewardCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.navigateTo('rewards'),
        borderRadius: BorderRadius.circular(20),
        child: NeonPanel(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: <Widget>[
              const Icon(Icons.calendar_month_rounded, color: OrbitColors.gold, size: 26),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.text('daily_rewards'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Text(
                      controller.dailyRewardAvailable
                          ? '${strings.text('claim_reward')}  ·  ${strings.text('streak', <String, Object>{'value': controller.save.dailyStreak})}'
                          : strings.text('claimed_today'),
                      style: const TextStyle(color: OrbitColors.muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: OrbitColors.gold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _freeChestCard(BuildContext context) {
    final bool available = controller.freeChestAvailable;
    return NeonPanel(
      borderColor: OrbitColors.gold,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: <Widget>[
          const Icon(Icons.card_giftcard_rounded, color: OrbitColors.gold, size: 25),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(strings.text('free_chest'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 3),
                Text(strings.text('watch_optional', <String, Object>{'value': GameConfig.dailyChestCoins}), style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
              ],
            ),
          ),
          NeonButton(
            label: available ? strings.text('open_chest') : strings.text('claimed_today'),
            icon: available ? Icons.play_circle_outline_rounded : Icons.check_rounded,
            compact: true,
            color: OrbitColors.gold,
            enabled: available,
            onPressed: available
                ? () {
                    if (!controller.claimFreeChestWithRewardedAd()) controller.showMessage(strings.text('ads_unavailable'));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _missionsSummary() {
    final missions = DailyMissionRules.missionsFor(controller.save);
    if (missions.isEmpty) {
      return NeonPanel(child: Text(strings.text('missions_empty'), style: const TextStyle(color: OrbitColors.muted, fontSize: 11)));
    }
    final mission = missions.first;
    final int progress = controller.save.missionProgress[mission.id] ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.navigateTo('missions'),
        borderRadius: BorderRadius.circular(20),
        child: NeonPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              const Icon(Icons.track_changes_rounded, color: OrbitColors.cyan, size: 23),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(strings.missionTitle(mission.id, mission.title), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    ProgressMeter(value: progress / mission.goal, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$progress/${mission.goal}', style: const TextStyle(color: OrbitColors.cyan, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcuts(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _Shortcut(title: strings.text('shop_skins'), icon: Icons.face_rounded, color: OrbitColors.violet, onTap: () => controller.navigateTo('shop'))),
        const SizedBox(width: 9),
        Expanded(child: _Shortcut(title: strings.text('achievements'), icon: Icons.emoji_events_rounded, color: OrbitColors.gold, onTap: () => controller.navigateTo('achievements'))),
        const SizedBox(width: 9),
        Expanded(child: _Shortcut(title: strings.text('settings'), icon: Icons.tune_rounded, color: OrbitColors.cyan, onTap: () => controller.navigateTo('settings'))),
      ],
    );
  }

  Widget _leaderboardCard(BuildContext context) => NeonPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.leaderboard_rounded, color: OrbitColors.violet, size: 23),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.text('online_optional'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35))),
            TextButton(onPressed: () => controller.navigateTo('leaderboards'), child: Text(strings.text('leaderboards'), style: const TextStyle(color: OrbitColors.violet, fontSize: 9, fontWeight: FontWeight.w900))),
          ],
        ),
      );

  Widget _seeAll(VoidCallback callback) => TextButton(
        onPressed: callback,
        child: Text('${strings.text('see_all')}  ›', style: const TextStyle(color: OrbitColors.cyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      );

  String _compact(int value) => value >= 1000000 ? '${(value / 1000000).toStringAsFixed(1)}m' : value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.title, required this.icon, required this.color, required this.onTap});

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: OrbitColors.panel.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 70,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 21),
                const SizedBox(height: 4),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.text, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      );
}

class _OrbitArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.54, size.height * 0.52);
    final Paint ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      ring.color = (i.isEven ? OrbitColors.cyan : OrbitColors.violet).withValues(alpha: 0.17 - i * 0.025);
      canvas.drawCircle(center, 31 + i * 19, ring);
    }
    canvas.drawCircle(center, 10, Paint()..color = OrbitColors.cyan.withValues(alpha: 0.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13));
    canvas.drawCircle(center, 5.5, Paint()..color = OrbitColors.cyan);
    final List<Offset> stars = <Offset>[
      Offset(size.width * 0.41, size.height * 0.18),
      Offset(size.width * 0.76, size.height * 0.19),
      Offset(size.width * 0.86, size.height * 0.55),
      Offset(size.width * 0.34, size.height * 0.77),
      Offset(size.width * 0.66, size.height * 0.86),
      Offset(size.width * 0.52, size.height * 0.1),
    ];
    for (int i = 0; i < stars.length; i++) {
      canvas.drawCircle(stars[i], i.isEven ? 1.5 : 1, Paint()..color = Colors.white.withValues(alpha: 0.58));
    }
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2 + math.pi / 8;
      final Offset p = center + Offset(math.cos(angle) * (49 + i * 2), math.sin(angle) * (49 + i * 2));
      canvas.drawCircle(p, i == 0 ? 4 : 2.7, Paint()..color = i.isEven ? OrbitColors.pink : OrbitColors.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitArtworkPainter oldDelegate) => false;
}
