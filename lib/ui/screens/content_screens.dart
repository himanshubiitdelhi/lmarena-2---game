import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../config/game_config.dart';
import '../../domain/achievements.dart';
import '../../domain/economy.dart';
import '../../l10n/app_strings.dart';
import '../widgets/neon_widgets.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final List<DailyMissionDefinition> missions = DailyMissionRules.missionsFor(controller.save);
    return _ContentShell(
      title: strings.text('missions'),
      controller: controller,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
        physics: const BouncingScrollPhysics(),
        itemCount: missions.length + 1,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 11),
        itemBuilder: (BuildContext context, int index) {
          if (index == missions.length) {
            return NeonPanel(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.refresh_rounded, color: OrbitColors.violet),
                  const SizedBox(width: 10),
                  Expanded(child: Text(strings.text('missions_empty'), style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.4))),
                ],
              ),
            );
          }
          final DailyMissionDefinition mission = missions[index];
          final int progress = controller.save.missionProgress[mission.id] ?? 0;
          final bool complete = progress >= mission.goal;
          final bool claimed = controller.save.claimedMissionIds.contains(mission.id);
          return NeonPanel(
            borderColor: complete && !claimed ? OrbitColors.gold : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(width: 38, height: 38, decoration: BoxDecoration(color: (complete ? OrbitColors.gold : OrbitColors.cyan).withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)), child: Icon(complete ? Icons.task_alt_rounded : Icons.track_changes_rounded, color: complete ? OrbitColors.gold : OrbitColors.cyan, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(strings.missionTitle(mission.id, mission.title), style: const TextStyle(color: OrbitColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('${strings.text('progress')}: $progress / ${mission.goal}', style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
                        ],
                      ),
                    ),
                    if (claimed)
                      const Icon(Icons.check_circle_rounded, color: OrbitColors.gold)
                    else if (complete)
                      NeonButton(
                        label: strings.text('claim'),
                        icon: Icons.card_giftcard_rounded,
                        color: OrbitColors.gold,
                        compact: true,
                        onPressed: () => controller.claimMission(mission.id),
                      )
                    else
                      Text('+${GameConfig.missionRewardCoins} ●', style: const TextStyle(color: OrbitColors.gold, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressMeter(value: progress / mission.goal, color: complete ? OrbitColors.gold : OrbitColors.cyan),
                const SizedBox(height: 7),
                Text(
                  claimed ? strings.text('claimed_today') : complete ? strings.text('mission_ready') : strings.text('daily_challenge'),
                  style: TextStyle(color: complete ? OrbitColors.gold : OrbitColors.muted, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final int unlockedCount = controller.save.unlockedAchievements.length;
    final int total = AchievementRules.all.length;
    return _ContentShell(
      title: strings.text('achievements'),
      controller: controller,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
        physics: const BouncingScrollPhysics(),
        itemCount: AchievementRules.all.length + 1,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 9),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return NeonPanel(
              borderColor: OrbitColors.gold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[const Icon(Icons.emoji_events_rounded, color: OrbitColors.gold), const SizedBox(width: 10), Expanded(child: Text('$unlockedCount / $total ${strings.text('unlocked').toLowerCase()}', style: const TextStyle(color: OrbitColors.text, fontWeight: FontWeight.w900, fontSize: 12)))]),
                  const SizedBox(height: 11),
                  ProgressMeter(value: unlockedCount / total, color: OrbitColors.gold),
                  const SizedBox(height: 7),
                  Text('${strings.text('total_planets')}: ${controller.save.lifetimePlanets}  ·  ${strings.text('total_perfects')}: ${controller.save.lifetimePerfects}', style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
                ],
              ),
            );
          }
          final AchievementDefinition achievement = AchievementRules.all[index - 1];
          final bool unlocked = controller.save.unlockedAchievements.contains(achievement.id);
          return NeonPanel(
            borderColor: unlocked ? OrbitColors.gold : null,
            padding: const EdgeInsets.all(13),
            child: Row(
              children: <Widget>[
                Container(width: 43, height: 43, decoration: BoxDecoration(color: (unlocked ? OrbitColors.gold : OrbitColors.panelLight).withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded, color: unlocked ? OrbitColors.gold : OrbitColors.muted, size: 21)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(strings.achievementTitle(achievement.id, achievement.title), style: TextStyle(color: unlocked ? OrbitColors.text : OrbitColors.muted, fontSize: 11, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(unlocked ? strings.achievementDescription(achievement.id, achievement.description) : strings.text('locked_hint'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_rounded, color: unlocked ? OrbitColors.gold : OrbitColors.muted, size: 17),
                    const SizedBox(height: 5),
                    Text('+${achievement.coinReward} ●', style: TextStyle(color: unlocked ? OrbitColors.gold : OrbitColors.muted, fontSize: 8, fontWeight: FontWeight.w800)),
                    if (achievement.gemReward > 0) Text('+${achievement.gemReward} ◆', style: TextStyle(color: unlocked ? OrbitColors.violet : OrbitColors.muted, fontSize: 8, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DailyRewardsScreen extends StatelessWidget {
  const DailyRewardsScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final int nextDay = controller.save.dailyRewardDay.clamp(0, 6).toInt();
    return _ContentShell(
      title: strings.text('daily_calendar'),
      controller: controller,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          NeonPanel(
            borderColor: OrbitColors.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.local_fire_department_rounded, color: OrbitColors.gold, size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Text(strings.text('streak', <String, Object>{'value': controller.save.dailyStreak}), style: const TextStyle(color: OrbitColors.text, fontSize: 15, fontWeight: FontWeight.w900))),
                    if (controller.save.freeStreakFreezeAvailable) Chip(avatar: const Icon(Icons.ac_unit_rounded, size: 14, color: OrbitColors.cyan), label: Text(strings.text('streak_freeze'), style: const TextStyle(fontSize: 8)), side: BorderSide.none, backgroundColor: OrbitColors.cyan.withValues(alpha: 0.09)),
                  ],
                ),
                const SizedBox(height: 9),
                Text(strings.text('freeze_explain'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.45)),
                const SizedBox(height: 14),
                for (int index = 0; index < GameConfig.dailyCoinRewards.length; index++) ...<Widget>[
                  _RewardDayCard(
                    day: index + 1,
                    coins: GameConfig.dailyCoinRewards[index],
                    gems: GameConfig.dailyGemRewards[index],
                    active: controller.dailyRewardAvailable && index == nextDay,
                    claimed: index < nextDay ||
                        (!controller.dailyRewardAvailable && index == (nextDay == 0 ? 6 : nextDay - 1)),
                    strings: strings,
                  ),
                  if (index != GameConfig.dailyCoinRewards.length - 1) const SizedBox(height: 7),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: controller.dailyRewardAvailable ? strings.text('claim_reward') : strings.text('claimed_today'),
                    icon: controller.dailyRewardAvailable ? Icons.card_giftcard_rounded : Icons.check_rounded,
                    color: OrbitColors.gold,
                    enabled: controller.dailyRewardAvailable,
                    onPressed: controller.dailyRewardAvailable
                        ? () {
                            final DailyRewardResult result = controller.claimDailyReward();
                            if (result.claimed) {
                              controller.showMessage('${strings.text('unlocked')}: +${result.coins} ●  +${result.gems} ◆');
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          NeonPanel(
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline_rounded, color: OrbitColors.cyan),
                const SizedBox(width: 10),
                Expanded(child: Text(strings.text('freeze_explain'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardDayCard extends StatelessWidget {
  const _RewardDayCard({required this.day, required this.coins, required this.gems, required this.active, required this.claimed, required this.strings});

  final int day;
  final int coins;
  final int gems;
  final bool active;
  final bool claimed;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? OrbitColors.gold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? OrbitColors.gold.withValues(alpha: 0.56) : Colors.white.withValues(alpha: 0.055)),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(width: 52, child: Text(strings.text('day', <String, Object>{'value': day}), style: TextStyle(color: active ? OrbitColors.gold : OrbitColors.muted, fontSize: 9, fontWeight: FontWeight.w900))),
            const Icon(Icons.circle, color: OrbitColors.gold, size: 9),
            const SizedBox(width: 5),
            Text('$coins', style: const TextStyle(color: OrbitColors.text, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            const Icon(Icons.diamond_rounded, color: OrbitColors.violet, size: 12),
            const SizedBox(width: 4),
            Text('$gems', style: const TextStyle(color: OrbitColors.text, fontSize: 10, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (claimed)
              const Icon(Icons.check_circle_rounded, color: OrbitColors.gold, size: 16)
            else if (active)
              Text(strings.text('today'), style: const TextStyle(color: OrbitColors.gold, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.9))
            else
              const Icon(Icons.lock_outline_rounded, color: OrbitColors.muted, size: 14),
          ],
        ),
      );
}

class LeaderboardsScreen extends StatelessWidget {
  const LeaderboardsScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => _ContentShell(
        title: strings.text('leaderboards'),
        controller: controller,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            NeonPanel(
              borderColor: OrbitColors.violet,
              child: Column(
                children: <Widget>[
                  const Icon(Icons.leaderboard_rounded, color: OrbitColors.violet, size: 42),
                  const SizedBox(height: 10),
                  Text(strings.text('online_optional'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.5)),
                  const SizedBox(height: 15),
                  NeonButton(
                    label: controller.playGames.signedIn ? 'PLAY GAMES CONNECTED' : strings.text('sign_in'),
                    icon: Icons.sports_esports_rounded,
                    color: OrbitColors.violet,
                    onPressed: () => unawaited(controller.signInToPlayGames()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(child: NeonButton(label: strings.text('classic_board'), icon: Icons.public_rounded, color: OrbitColors.cyan, secondary: true, onPressed: () => unawaited(controller.showLeaderboard()))),
                      const SizedBox(width: 9),
                      Expanded(child: NeonButton(label: strings.text('daily_board'), icon: Icons.today_rounded, color: OrbitColors.pink, secondary: true, onPressed: () => unawaited(controller.showLeaderboard(daily: true)))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                Expanded(child: _LocalScore(title: strings.text('classic_best'), value: controller.save.bestScore, color: OrbitColors.cyan)),
                const SizedBox(width: 10),
                Expanded(child: _LocalScore(title: strings.text('daily_best'), value: controller.save.dailyChallengeBest, color: OrbitColors.pink)),
              ],
            ),
            const SizedBox(height: 12),
            NeonPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.text('offline'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text('${strings.text('run_count')}: ${controller.save.totalRuns}\n${strings.text('total_planets')}: ${controller.save.lifetimePlanets}\n${strings.text('total_perfects')}: ${controller.save.lifetimePerfects}', style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LocalScore extends StatelessWidget {
  const _LocalScore({required this.title, required this.value, required this.color});

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => NeonPanel(
        borderColor: color,
        child: Column(children: <Widget>[Text(title, textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8)), const SizedBox(height: 6), Text('$value', style: TextStyle(color: color, fontSize: 27, fontWeight: FontWeight.w900))]),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => _ContentShell(
        title: strings.text('settings'),
        controller: controller,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            NeonPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _SettingSwitch(title: strings.text('sound'), icon: Icons.volume_up_rounded, value: controller.save.soundEnabled, onChanged: (bool value) => unawaited(controller.setSoundEnabled(value))),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  _SettingSwitch(title: strings.text('music'), icon: Icons.music_note_rounded, value: controller.save.musicEnabled, onChanged: (bool value) => unawaited(controller.setMusicEnabled(value))),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  _SettingSwitch(title: strings.text('analytics_reporting'), subtitle: strings.text('analytics_desc'), icon: Icons.analytics_rounded, value: controller.save.analyticsEnabled, onChanged: (bool value) => unawaited(controller.setAnalyticsEnabled(value))),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  _SettingSwitch(title: strings.text('haptics'), icon: Icons.vibration_rounded, value: controller.save.hapticsEnabled, onChanged: controller.setHapticsEnabled),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  _SettingSwitch(title: strings.text('reduced_motion'), icon: Icons.motion_photos_off_rounded, value: controller.save.reducedMotion, onChanged: controller.setReducedMotion),
                ],
              ),
            ),
            const SizedBox(height: 13),
            NeonPanel(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.translate_rounded, color: OrbitColors.cyan),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.text('language'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w800))),
                  DropdownButton<String>(
                    value: controller.save.languageCode,
                    dropdownColor: OrbitColors.panelLight,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w800),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'en', child: Text('English')),
                      DropdownMenuItem<String>(value: 'hi', child: Text('हिन्दी')),
                      DropdownMenuItem<String>(value: 'es', child: Text('Español')),
                      DropdownMenuItem<String>(value: 'pt', child: Text('Português')),
                      DropdownMenuItem<String>(value: 'id', child: Text('Bahasa Indonesia')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) controller.setLanguage(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            NeonPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_rounded, color: OrbitColors.violet),
                    title: Text(strings.text('privacy_policy'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                    subtitle: Text(strings.text('privacy_summary'), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: OrbitColors.muted),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  ListTile(
                    leading: const Icon(Icons.tune_rounded, color: OrbitColors.cyan),
                    title: Text(strings.text('privacy_options'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                    subtitle: Text(strings.text('optional_ads'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35)),
                    trailing: const Icon(Icons.open_in_new_rounded, color: OrbitColors.muted, size: 17),
                    onTap: () async {
                      if (!controller.ads.privacyOptionsRequired) {
                        controller.showMessage(strings.text('privacy_summary'));
                        return;
                      }
                      await controller.openPrivacyOptions();
                    },
                  ),
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: OrbitColors.gold),
                    title: Text(strings.text('restore'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                    subtitle: Text(strings.text('restore_desc'), style: const TextStyle(color: OrbitColors.muted, fontSize: 9)),
                    onTap: () => unawaited(controller.restorePurchases()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            NeonPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.text('offline'), style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('${strings.text('ages')}\n${strings.text('no_banners')}', style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text('ORBIT HOP  ·  v${GameConfig.versionName}', style: const TextStyle(color: OrbitColors.muted, fontSize: 8, letterSpacing: 1))),
          ],
        ),
      );

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: OrbitColors.panel,
        title: Text(strings.text('privacy_policy'), style: const TextStyle(color: OrbitColors.text, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(child: Text('${strings.text('privacy_summary')}\n\n${strings.text('optional_ads')}\n\n${strings.text('offline')}\n\n${strings.text('ages')}', style: const TextStyle(color: OrbitColors.muted, fontSize: 12, height: 1.55))),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.text('back_home'), style: const TextStyle(color: OrbitColors.cyan)))],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({required this.title, required this.icon, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        dense: true,
        secondary: Icon(icon, color: OrbitColors.cyan, size: 19),
        title: Text(title, style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w800)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: OrbitColors.muted, fontSize: 8)),
        value: value,
        activeThumbColor: OrbitColors.cyan,
        onChanged: onChanged,
      );
}

class _ContentShell extends StatelessWidget {
  const _ContentShell({required this.title, required this.controller, required this.child});

  final String title;
  final AppController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppBackdrop(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: ScreenHeader(title: title, onBack: () => controller.navigateTo('home')),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
}
