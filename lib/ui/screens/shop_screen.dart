import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../config/game_config.dart';
import '../../domain/achievements.dart';
import '../../domain/catalog.dart';
import '../../domain/economy.dart';
import '../../services/purchase_service.dart';
import '../../l10n/app_strings.dart';
import '../widgets/neon_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.controller, required this.strings});

  final AppController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: AppBackdrop(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: ScreenHeader(title: strings.text('shop'), onBack: () => controller.navigateTo('home')),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      CurrencyPill(icon: Icons.circle, value: '${controller.save.coins}', color: OrbitColors.gold),
                      const SizedBox(width: 9),
                      CurrencyPill(icon: Icons.diamond_rounded, value: '${controller.save.gems}', color: OrbitColors.violet),
                      const Spacer(),
                      Flexible(child: Text(strings.text('earn_coins'), textAlign: TextAlign.right, style: const TextStyle(color: OrbitColors.muted, fontSize: 8, height: 1.3))),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: OrbitColors.cyan,
                  unselectedLabelColor: OrbitColors.muted,
                  indicatorColor: OrbitColors.cyan,
                  labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  tabs: <Widget>[
                    Tab(text: strings.text('shop_skins')),
                    Tab(text: strings.text('shop_trails')),
                    Tab(text: strings.text('shop_themes')),
                    Tab(text: strings.text('shop_upgrades')),
                    Tab(text: strings.text('shop_packs')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _skins(),
                      _trails(),
                      _themes(),
                      _upgrades(),
                      _packs(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _skins() => GridView.builder(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 24),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, childAspectRatio: 0.8),
        itemCount: CosmeticCatalog.skins.length,
        itemBuilder: (BuildContext context, int index) {
          final SkinDefinition item = CosmeticCatalog.skins[index];
          final bool owned = controller.save.ownedSkins.contains(item.id);
          final bool equipped = controller.save.equippedSkin == item.id;
          final bool locked = item.achievementId != null && !AchievementRules.isUnlocked(controller.save, item.achievementId);
          final String cost = item.gemCost > 0 ? '${item.gemCost}  ◆' : item.coinCost > 0 ? '${item.coinCost}  ●' : strings.text('owned');
          return _CosmeticCard(
            name: item.name,
            color: Color(item.colorArgb),
            icon: BlobPreview(color: Color(item.colorArgb), size: 46, shape: item.shape),
            detail: locked ? _achievementName(item.achievementId!) : cost,
            button: equipped ? strings.text('equipped') : owned ? strings.text('equip') : locked ? strings.text('locked') : strings.text('buy'),
            buttonColor: locked ? OrbitColors.muted : OrbitColors.cyan,
            enabled: !equipped,
            onPressed: () {
              if (owned) {
                controller.equipSkin(item.id);
              } else if (locked) {
                controller.showMessage('${strings.text('locked')}: ${_achievementName(item.achievementId!)}');
              } else {
                _reportPurchase(controller.unlockSkin(item.id));
              }
            },
          );
        },
      );

  Widget _trails() => GridView.builder(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 24),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, childAspectRatio: 0.8),
        itemCount: CosmeticCatalog.trails.length,
        itemBuilder: (BuildContext context, int index) {
          final TrailDefinition item = CosmeticCatalog.trails[index];
          final Color color = Color(item.colorArgb);
          final bool owned = controller.save.ownedTrails.contains(item.id);
          final bool equipped = controller.save.equippedTrail == item.id;
          final bool locked = item.achievementId != null && !AchievementRules.isUnlocked(controller.save, item.achievementId);
          return _CosmeticCard(
            name: item.name,
            color: color,
            icon: Icon(Icons.auto_awesome_rounded, color: color, size: 38),
            detail: locked ? _achievementName(item.achievementId!) : item.coinCost > 0 ? '${item.coinCost}  ●' : strings.text('owned'),
            button: equipped ? strings.text('equipped') : owned ? strings.text('equip') : locked ? strings.text('locked') : strings.text('buy'),
            buttonColor: color,
            enabled: !equipped,
            onPressed: () {
              if (owned) {
                controller.equipTrail(item.id);
              } else if (locked) {
                controller.showMessage('${strings.text('locked')}: ${_achievementName(item.achievementId!)}');
              } else {
                _reportPurchase(controller.unlockTrail(item.id));
              }
            },
          );
        },
      );

  Widget _themes() => GridView.builder(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 24),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, childAspectRatio: 0.8),
        itemCount: CosmeticCatalog.themes.length,
        itemBuilder: (BuildContext context, int index) {
          final ThemeDefinition item = CosmeticCatalog.themes[index];
          final Color accent = Color(item.accentArgb);
          final bool owned = controller.save.ownedThemes.contains(item.id);
          final bool equipped = controller.save.equippedTheme == item.id;
          final bool locked = item.achievementId != null && !AchievementRules.isUnlocked(controller.save, item.achievementId);
          return _CosmeticCard(
            name: item.name,
            color: accent,
            icon: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: <Color>[Color(item.backgroundArgb), Color(item.secondaryArgb), accent]),
                border: Border.all(color: accent.withValues(alpha: 0.5), width: 2),
                boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 13)],
              ),
              child: Icon(Icons.blur_circular_rounded, color: Colors.white.withValues(alpha: 0.8), size: 25),
            ),
            detail: locked ? _achievementName(item.achievementId!) : item.coinCost > 0 ? '${item.coinCost}  ●' : strings.text('owned'),
            button: equipped ? strings.text('equipped') : owned ? strings.text('equip') : locked ? strings.text('locked') : strings.text('buy'),
            buttonColor: accent,
            enabled: !equipped,
            onPressed: () {
              if (owned) {
                controller.equipTheme(item.id);
              } else if (locked) {
                controller.showMessage('${strings.text('locked')}: ${_achievementName(item.achievementId!)}');
              } else {
                _reportPurchase(controller.unlockTheme(item.id));
              }
            },
          );
        },
      );

  Widget _upgrades() => ListView.separated(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: UpgradeType.values.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 11),
        itemBuilder: (BuildContext context, int index) {
          final UpgradeType type = UpgradeType.values[index];
          final int level = controller.save.upgradeLevel(type.key);
          final bool maxed = level >= type.maxLevel;
          final int cost = EconomyRules.upgradeCost(type, level);
          final String title = strings.text('upgrade_${type.key}', <String, Object>{});
          final String description = strings.text('upgrade_desc_${type.key}', <String, Object>{});
          return NeonPanel(
            borderColor: OrbitColors.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: OrbitColors.cyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)), child: Icon(_upgradeIcon(type), color: OrbitColors.cyan, size: 20)),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(color: OrbitColors.text, fontWeight: FontWeight.w900, fontSize: 13)), const SizedBox(height: 3), Text(description, style: const TextStyle(color: OrbitColors.muted, fontSize: 10))])),
                    Text('$level/${type.maxLevel}', style: const TextStyle(color: OrbitColors.cyan, fontSize: 11, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: <Widget>[
                    Expanded(child: Row(children: List<Widget>.generate(type.maxLevel, (int i) => Expanded(child: Container(height: 5, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: i < level ? OrbitColors.cyan : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5))))))),
                    const SizedBox(width: 12),
                    NeonButton(
                      label: maxed ? strings.text('max_level') : '$cost  ●',
                      icon: maxed ? Icons.check_rounded : Icons.upgrade_rounded,
                      color: OrbitColors.cyan,
                      compact: true,
                      enabled: !maxed,
                      onPressed: maxed ? null : () => _reportPurchase(controller.purchaseUpgrade(type)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _packs() {
    final List<_StoreOffer> offers = <_StoreOffer>[
      _StoreOffer(id: GameConfig.productRemoveAds, title: strings.text('remove_ads'), detail: strings.text('remove_ads_desc'), icon: Icons.do_not_disturb_on_rounded, color: OrbitColors.cyan),
      _StoreOffer(id: GameConfig.productGems, title: strings.text('gem_pack'), detail: strings.text('gem_pack_desc'), icon: Icons.diamond_rounded, color: OrbitColors.violet),
      _StoreOffer(id: GameConfig.productStarterBundle, title: strings.text('starter_bundle'), detail: strings.text('starter_bundle_desc'), icon: Icons.redeem_rounded, color: OrbitColors.gold),
    ];
    final bool verificationConfigured = controller.purchases.verificationConfigured;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: offers.length + 2,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 11),
      itemBuilder: (BuildContext context, int index) {
        if (index == offers.length) {
          return NeonPanel(child: Text('${strings.text('products_test')}\n\n${strings.text('earn_coins')}', style: const TextStyle(color: OrbitColors.muted, fontSize: 10, height: 1.5)));
        }
        if (index == offers.length + 1) {
          return NeonButton(label: strings.text('restore'), icon: Icons.restore_rounded, secondary: true, color: OrbitColors.violet, onPressed: () => unawaited(controller.restorePurchases()));
        }
        final _StoreOffer offer = offers[index];
        final ProductDetails? product = controller.purchases.product(offer.id);
        final bool owned = offer.id == GameConfig.productRemoveAds && controller.save.removeAdsOwned ||
            offer.id == GameConfig.productStarterBundle && controller.save.starterBundleOwned;
        final bool starterLocked = offer.id == GameConfig.productStarterBundle && controller.save.totalRuns < 5;
        final bool isDisabled = owned || starterLocked || !verificationConfigured || product == null || controller.purchases.busy;
        final String price = product?.price ?? '—';
        return NeonPanel(
          borderColor: offer.color,
          child: Row(
            children: <Widget>[
              Container(width: 44, height: 44, decoration: BoxDecoration(color: offer.color.withValues(alpha: 0.13), shape: BoxShape.circle), child: Icon(offer.icon, color: offer.color, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(offer.title, style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(offer.detail, style: const TextStyle(color: OrbitColors.muted, fontSize: 9, height: 1.35)),
                    if (!verificationConfigured) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(strings.text('verification_unconfigured'), style: const TextStyle(color: OrbitColors.pink, fontSize: 8)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NeonButton(
                label: owned ? strings.text('owned') : starterLocked ? strings.text('run_five') : price,
                icon: owned ? Icons.check_rounded : Icons.shopping_bag_rounded,
                color: offer.color,
                compact: true,
                enabled: !isDisabled,
                onPressed: isDisabled ? null : () => unawaited(controller.buyProduct(offer.id)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _achievementName(String id) {
    for (final AchievementDefinition achievement in AchievementRules.all) {
      if (achievement.id == id) return strings.achievementTitle(achievement.id, achievement.title);
    }
    return strings.text('locked');
  }

  IconData _upgradeIcon(UpgradeType type) => switch (type) {
        UpgradeType.coinMagnet => Icons.control_camera_rounded,
        UpgradeType.landingZone => Icons.radio_button_checked_rounded,
        UpgradeType.feverTime => Icons.local_fire_department_rounded,
        UpgradeType.runShield => Icons.shield_rounded,
        UpgradeType.startingScore => Icons.rocket_launch_rounded,
      };

  void _reportPurchase(EconomyResult result) {
    final String message = switch (result) {
      EconomyResult.success => strings.text('unlocked'),
      EconomyResult.insufficientFunds => strings.text('not_enough_currency'),
      EconomyResult.maxLevel => strings.text('max_level'),
      EconomyResult.alreadyOwned => strings.text('owned'),
      EconomyResult.unknownItem => strings.text('locked_hint'),
    };
    controller.showMessage(message);
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.name,
    required this.color,
    required this.icon,
    required this.detail,
    required this.button,
    required this.buttonColor,
    required this.enabled,
    required this.onPressed,
  });

  final String name;
  final Color color;
  final Widget icon;
  final String detail;
  final String button;
  final Color buttonColor;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => NeonPanel(
        padding: const EdgeInsets.all(12),
        borderColor: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(children: <Widget>[Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.text, fontSize: 11, fontWeight: FontWeight.w900))), Icon(Icons.auto_awesome, color: color, size: 13)]),
            icon,
            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: detail.contains('zone_') ? OrbitColors.muted : color, fontSize: 9, fontWeight: FontWeight.w800)),
            SizedBox(width: double.infinity, child: NeonButton(label: button, onPressed: onPressed, color: buttonColor, compact: true, enabled: enabled)),
          ],
        ),
      );
}

class _StoreOffer {
  const _StoreOffer({required this.id, required this.title, required this.detail, required this.icon, required this.color});

  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}
