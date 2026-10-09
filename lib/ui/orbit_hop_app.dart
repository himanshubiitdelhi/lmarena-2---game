import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../domain/game_models.dart';
import '../l10n/app_strings.dart';
import 'screens/content_screens.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'widgets/neon_widgets.dart';

class OrbitHopApp extends StatefulWidget {
  const OrbitHopApp({super.key});

  @override
  State<OrbitHopApp> createState() => _OrbitHopAppState();
}

class _OrbitHopAppState extends State<OrbitHopApp> {
  late Future<AppController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = AppController.create();
  }

  void _retry() => setState(() => _controllerFuture = AppController.create());

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ORBIT HOP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: OrbitColors.background,
          colorScheme: const ColorScheme.dark(
            primary: OrbitColors.cyan,
            secondary: OrbitColors.violet,
            surface: OrbitColors.panel,
            error: OrbitColors.pink,
          ),
          splashFactory: InkSparkle.splashFactory,
          visualDensity: VisualDensity.standard,
          textTheme: ThemeData.dark().textTheme.apply(bodyColor: OrbitColors.text, displayColor: OrbitColors.text),
        ),
        home: FutureBuilder<AppController>(
          future: _controllerFuture,
          builder: (BuildContext context, AsyncSnapshot<AppController> snapshot) {
            final AppStrings startupStrings = AppStrings(WidgetsBinding.instance.platformDispatcher.locale.languageCode);
            if (snapshot.hasData) return OrbitHopRoot(controller: snapshot.data!);
            if (snapshot.hasError) {
              return _BootstrapError(onRetry: _retry, strings: startupStrings);
            }
            return _LoadingScreen(strings: startupStrings);
          },
        ),
      );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackdrop(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.blur_circular_rounded, color: OrbitColors.cyan, size: 62),
                const SizedBox(height: 17),
                const Text('ORBIT HOP', style: TextStyle(color: OrbitColors.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const SizedBox(height: 10),
                Text(strings.text('loading'), style: const TextStyle(color: OrbitColors.muted, fontSize: 11)),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: OrbitColors.cyan, strokeWidth: 2),
              ],
            ),
          ),
        ),
      );
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.onRetry, required this.strings});

  final VoidCallback onRetry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackdrop(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.cloud_off_rounded, color: OrbitColors.pink, size: 50),
                  const SizedBox(height: 12),
                  Text(strings.text('save_store_error'), textAlign: TextAlign.center, style: const TextStyle(color: OrbitColors.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 15),
                  NeonButton(label: strings.text('try_again'), onPressed: onRetry, color: OrbitColors.cyan),
                ],
              ),
            ),
          ),
        ),
      );
}

class OrbitHopRoot extends StatefulWidget {
  const OrbitHopRoot({super.key, required this.controller});

  final AppController controller;

  @override
  State<OrbitHopRoot> createState() => _OrbitHopRootState();
}

class _OrbitHopRootState extends State<OrbitHopRoot> with WidgetsBindingObserver {
  Timer? _messageTimer;
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(covariant OrbitHopRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerChanged);
      oldWidget.controller.dispose();
      widget.controller.addListener(_controllerChanged);
    }
  }

  void _controllerChanged() {
    if (!mounted) return;
    final String message = widget.controller.message;
    if (message.isNotEmpty && message != _lastMessage) {
      _lastMessage = message;
      _messageTimer?.cancel();
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && widget.controller.message == message) widget.controller.clearMessage();
      });
    } else if (message.isEmpty) {
      _lastMessage = '';
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      widget.controller.pauseGame();
    }
  }

  void _onBack() {
    final AppController controller = widget.controller;
    if (controller.currentPage == 'game') {
      final OrbitHopGame? game = controller.game;
      if (game != null && game.phase != RunPhase.gameOver && game.phase != RunPhase.paused) {
        controller.pauseGame();
        return;
      }
      controller.leaveGame();
      return;
    }
    if (controller.currentPage != 'home') {
      controller.navigateTo('home');
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = widget.controller;
    final AppStrings strings = AppStrings(controller.save.languageCode);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: OrbitColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 230),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(key: ValueKey<String>(controller.currentPage), child: _page(controller, strings)),
            ),
            if (controller.message.isNotEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: SafeArea(
                  top: false,
                  child: _MessageToast(message: controller.message, onTap: controller.clearMessage),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page(AppController controller, AppStrings strings) => switch (controller.currentPage) {
        'game' => GameScreen(controller: controller, strings: strings),
        'shop' => ShopScreen(controller: controller, strings: strings),
        'settings' => SettingsScreen(controller: controller, strings: strings),
        'missions' => MissionsScreen(controller: controller, strings: strings),
        'achievements' => AchievementsScreen(controller: controller, strings: strings),
        'rewards' => DailyRewardsScreen(controller: controller, strings: strings),
        'leaderboards' => LeaderboardsScreen(controller: controller, strings: strings),
        _ => HomeScreen(controller: controller, strings: strings),
      };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_controllerChanged);
    widget.controller.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }
}

class _MessageToast extends StatelessWidget {
  const _MessageToast({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: OrbitColors.panelLight,
        borderRadius: BorderRadius.circular(16),
        elevation: 9,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: OrbitColors.cyan.withValues(alpha: 0.36))),
            child: Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_rounded, color: OrbitColors.cyan, size: 17),
                const SizedBox(width: 9),
                Expanded(child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: OrbitColors.text, fontSize: 10, height: 1.35, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                const Icon(Icons.close_rounded, color: OrbitColors.muted, size: 16),
              ],
            ),
          ),
        ),
      );
}
