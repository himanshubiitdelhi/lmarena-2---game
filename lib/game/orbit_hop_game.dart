import 'dart:collection';
import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../domain/catalog.dart';
import '../domain/economy.dart';
import '../domain/game_models.dart';
import '../l10n/app_strings.dart';

class OrbitHopGame extends FlameGame {
  OrbitHopGame({
    required int seed,
    required int runNumber,
    required this.isDailyChallenge,
    required this.tutorialEnabled,
    required this.languageCode,
    required this.skin,
    required this.trail,
    required this.theme,
    required this.upgradeLevels,
    required this.reducedMotion,
    this.onRunStarted,
    this.onRunEnded,
    this.onTutorialCompleted,
    this.onLanding,
    this.onLaunch,
    this.onCoinCollected,
    this.onFeverStarted,
    this.onShieldSaved,
    this.onDeath,
    this.onZoneChanged,
  }) : initialSeed = seed,
       _runNumber = runNumber,
       hud = ValueNotifier<RunHudState>(
         RunHudState(
           phase: RunPhase.ready,
           score: 0,
           combo: 0,
           multiplier: 1,
           runCoins: 0,
           runGems: 0,
           feverSeconds: 0,
           isFever: false,
           isDailyChallenge: isDailyChallenge,
           tutorialVisible: tutorialEnabled,
           perfectFlash: 0,
           zoneIndex: 0,
         ),
       );

  final int initialSeed;
  final bool isDailyChallenge;
  final bool tutorialEnabled;
  final String languageCode;
  final String skin;
  final String trail;
  final String theme;
  final Map<String, int> upgradeLevels;
  final bool reducedMotion;
  final void Function(int runNumber, bool daily)? onRunStarted;
  final void Function(RunResult result)? onRunEnded;
  final VoidCallback? onTutorialCompleted;
  final void Function(bool perfect, int combo)? onLanding;
  final VoidCallback? onLaunch;
  final void Function(PickupKind kind)? onCoinCollected;
  final VoidCallback? onFeverStarted;
  final VoidCallback? onShieldSaved;
  final VoidCallback? onDeath;
  final void Function(int zone, bool fever)? onZoneChanged;
  final ValueNotifier<RunHudState> hud;

  final List<OrbitPlanet> _planets = <OrbitPlanet>[];
  final List<_Pickup> _pickups = <_Pickup>[];
  final List<ParticleState> _particles = <ParticleState>[];
  final Queue<Offset> _trailPositions = Queue<Offset>();
  final List<_Star> _stars = <_Star>[];
  late StableRandom _random;
  late StableRandom _starRandom;
  OrbitPlanet? _currentPlanet;
  OrbitPlanet? _nextPlanet;
  RunPhase _phase = RunPhase.ready;
  Vec2 _player = const Vec2(0, 0);
  Vec2 _launchStart = const Vec2(0, 0);
  Vec2 _launchDirection = const Vec2(0, 0);
  double _playerAngle = math.pi * 0.77;
  double _idealLaunchAngle = math.pi;
  double _cameraY = 0;
  double _dangerY = 0;
  double _elapsed = 0;
  double _runElapsed = 0;
  double _flightDistance = 0;
  double _flightSpeed = 0;
  double _flightElapsed = 0;
  double _waitSeconds = 0;
  double _feverSeconds = 0;
  double _slowMotionSeconds = 0;
  double _perfectFlashSeconds = 0;
  double _shakeSeconds = 0;
  double _shakePower = 0;
  double _hudTimer = 0;
  double _messageSeconds = 0;
  String _message = '';
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _perfects = 0;
  int _runCoins = 0;
  int _runGems = 0;
  int _zone = 0;
  int _runNumber;
  int _revivesUsed = 0;
  int _shieldsRemaining = 0;
  bool _tutorialDone = false;
  bool _tutorialVisible = false;
  bool _initialized = false;
  bool _paused = false;
  RunPhase _phaseBeforePause = RunPhase.ready;
  bool _finalized = false;
  bool _fever = false;
  bool _runStarted = false;
  bool _visiblePerfect = false;
  DeathCause? _deathCause;
  String _deathLine = '';
  double _width = 0;
  double _height = 0;
  double _screenCenterX = 0;

  int get runNumber => _runNumber;
  RunPhase get phase => _phase;
  bool get isFinalized => _finalized;
  bool get isDaily => isDailyChallenge;
  int get score => _score;
  int get maxCombo => _maxCombo;
  int get runCoins => _runCoins;
  int get runGems => _runGems;

  @override
  Color backgroundColor() => const Color(0xFF101225);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _width = size.x;
    _height = size.y;
    _screenCenterX = _width * 0.5;
    if (!_initialized && _width > 0 && _height > 0) {
      _startNewRun(firstRun: true);
    }
  }

  void _startNewRun({required bool firstRun}) {
    if (_width <= 0 || _height <= 0) return;
    _initialized = true;
    _paused = false;
    _phase = RunPhase.ready;
    _finalized = false;
    _runStarted = true;
    _deathCause = null;
    _deathLine = '';
    _runElapsed = 0;
    _elapsed = 0;
    _flightDistance = 0;
    _flightSpeed = 0;
    _flightElapsed = 0;
    _waitSeconds = 0;
    _feverSeconds = 0;
    _slowMotionSeconds = 0;
    _perfectFlashSeconds = 0;
    _shakeSeconds = 0;
    _shakePower = 0;
    _messageSeconds = 0;
    _message = '';
    _score = isDailyChallenge ? 0 :
        (upgradeLevels['startingScore'] ?? 0) * GameConfig.startingScorePerLevel;
    _combo = 0;
    _maxCombo = 0;
    _perfects = 0;
    _runCoins = 0;
    _runGems = 0;
    _revivesUsed = 0;
    _shieldsRemaining = isDailyChallenge ? 0 :
        ((upgradeLevels['runShield'] ?? 0) > 0 ? GameConfig.freeShieldUsesPerRun : 0);
    if (firstRun) _tutorialDone = !tutorialEnabled;
    _tutorialVisible = tutorialEnabled && !_tutorialDone;
    _zone = GameConfig.zoneIndexAt(_score);
    _cameraY = 0;
    _random = StableRandom(firstRun ? initialSeed : _seedForRun());
    _starRandom = StableRandom(initialSeed ^ 0x53544152);
    _planets.clear();
    _pickups.clear();
    _particles.clear();
    _trailPositions.clear();
    _stars.clear();
    _createStars();

    final double scale = _scale;
    final double startY = _height * 0.62;
    final int direction = _random.nextInt(2) == 0 ? 1 : -1;
    _currentPlanet = OrbitPlanet(
      x: _screenCenterX,
      y: startY,
      radius: GameConfig.initialPlanetRadius * scale,
      orbitRadius: (GameConfig.initialPlanetRadius + GameConfig.orbitGap) * scale,
      spinSpeed: GameConfig.initialOrbitSpin,
      spinDirection: direction,
      phase: _random.between(0, math.pi * 2),
      seed: initialSeed,
    );
    _planets.add(_currentPlanet!);
    final double startBase = direction > 0 ? math.pi : 0;
    _playerAngle = startBase + _random.between(-math.pi, math.pi);
    _player = _orbitPoint(_currentPlanet!, _playerAngle);
    _dangerY = startY + _height * 1.12;
    _makeNextPlanet();
    onZoneChanged?.call(_zone, false);
    onRunStarted?.call(_runNumber, isDailyChallenge);
    _publishHud(force: true);
  }

  int _seedForRun() {
    if (isDailyChallenge) return initialSeed;
    return (initialSeed + _runNumber * 2654435761) & 0x7FFFFFFF;
  }

  double get _scale => _height <= 0 ? 1 : _height / 844;

  double _effectiveLandingWindow() {
    if (isDailyChallenge) return GameConfig.initialLandingWindow * _scale;
    final int level = upgradeLevels['landingZone'] ?? 0;
    final double feverBonus = _fever ? 13 * _scale : 0;
    return (GameConfig.initialLandingWindow +
            level * GameConfig.landingZoneBonusPerLevel +
            (feverBonus > 0 ? 13 : 0)) *
        _scale;
  }

  double _magnetRadius() {
    if (isDailyChallenge) return 0;
    return (upgradeLevels['coinMagnet'] ?? 0) *
        GameConfig.coinMagnetRadiusPerLevel *
        _scale;
  }

  Vec2 _orbitPoint(OrbitPlanet planet, double angle) => Vec2(
        planet.x + math.cos(angle) * planet.orbitRadius,
        planet.y + math.sin(angle) * planet.orbitRadius,
      );

  Vec2 _tangent(double angle, int direction) =>
      Vec2(-math.sin(angle) * direction, math.cos(angle) * direction).normalized();

  void _createStars() {
    for (int i = 0; i < GameConfig.starCount; i++) {
      _stars.add(_Star(
        x: _starRandom.nextDouble(),
        y: _starRandom.nextDouble(),
        radius: _starRandom.between(0.55, 1.7),
        twinkle: _starRandom.between(0, math.pi * 2),
        parallax: _starRandom.between(0.04, 0.2),
      ));
    }
  }

  void _makeNextPlanet() {
    final OrbitPlanet? current = _currentPlanet;
    if (current == null) return;
    final int nextScore = _score + 1;
    final int spinDirection = _random.nextInt(2) == 0 ? 1 : -1;
    final double baseAngle = current.spinDirection > 0 ? math.pi : 0;
    final double towardCenter = current.x < _screenCenterX ? 1 : -1;
    final double offsetSize = _random.between(0.07, 0.34);
    _idealLaunchAngle = baseAngle + towardCenter * offsetSize;
    final Vec2 idealStart = _orbitPoint(current, _idealLaunchAngle);
    final Vec2 tangent = _tangent(_idealLaunchAngle, current.spinDirection);
    final Vec2 normal = Vec2(-tangent.y, tangent.x);
    final double scale = _scale;
    final double radius = GameConfig.planetRadiusAt(nextScore) * scale;
    final double orbitRadius = radius + GameConfig.orbitGap * scale;
    final double travel = orbitRadius + GameConfig.targetOrbitDistance * scale +
        _random.between(-12, 18) * scale;
    final double sideShift = _random.between(-8, 8) * scale;
    final Vec2 idealCenter = idealStart + tangent * travel + normal * sideShift;
    final double minX = _width * 0.12;
    final double maxX = _width * 0.88;
    final double targetX = idealCenter.x.clamp(minX, maxX).toDouble();
    final double loopLevel = nextScore ~/ (GameConfig.zoneLength * GameConfig.zoneCount);
    final double spinSpeed = math.min(
      GameConfig.maximumOrbitSpin,
      GameConfig.spinAt(nextScore) + loopLevel * 0.18,
    ).toDouble();
    final bool moving = nextScore >= 4 &&
        _random.nextDouble() < math.min(0.62, 0.05 + nextScore * 0.012);
    final bool spiked = nextScore >= 9 &&
        _random.nextDouble() < math.min(0.65, 0.06 + (nextScore - 8) * 0.007);
    final bool shrinking = nextScore >= 15 &&
        _random.nextDouble() < math.min(0.35, 0.04 + (nextScore - 14) * 0.004);
    final double motionAmplitude = moving
        ? math.min(_width * 0.12, (18 + nextScore * 0.8) * scale).toDouble()
        : 0;
    final List<double> spikes = <double>[];
    if (spiked) {
      final int count = nextScore > 50 ? 3 : 2;
      final double expectedEntry = math.atan2(-tangent.y, -tangent.x);
      for (int i = 0; i < count; i++) {
        double spike = _random.between(-math.pi, math.pi);
        if (_wrapAngle(spike - expectedEntry).abs() < 0.62) {
          spike = _wrapAngle(spike + math.pi);
        }
        spikes.add(spike);
      }
    }
    final OrbitPlanet next = OrbitPlanet(
      x: targetX,
      y: idealCenter.y,
      radius: radius,
      orbitRadius: orbitRadius,
      spinSpeed: spinSpeed,
      spinDirection: spinDirection,
      phase: _random.between(0, math.pi * 2),
      seed: _random.nextInt(0x7FFFFFFF),
      motionAmplitude: motionAmplitude,
      motionFrequency: moving ? 0.42 + nextScore * 0.006 : 0,
      moving: moving,
      hasSpikes: spiked,
      spikeAngles: spikes,
    );
    _nextPlanet = next;
    _planets.add(next);

    _pickups.clear();
    final int coinCount = nextScore < 7 ? 3 : 2 + _random.nextInt(2);
    for (int i = 0; i < coinCount; i++) {
      final double progress = 0.25 + (i + 1) / (coinCount + 1) * 0.53;
      final Vec2 position = idealStart + tangent * (travel * progress) +
          normal * _random.between(-5, 5) * scale;
      _pickups.add(_Pickup(position.x, position.y, PickupKind.coin));
    }
    if (nextScore >= 3 && _random.nextInt(16) == 0) {
      final double progress = _random.between(0.55, 0.88);
      final Vec2 riskyPosition = idealStart + tangent * (travel * progress) +
          normal * _random.between(21, 39) * scale;
      _pickups.add(_Pickup(riskyPosition.x, riskyPosition.y, PickupKind.gem));
    }
  }

  void launch() {
    if (!_initialized || _phase != RunPhase.ready || _paused) return;
    final OrbitPlanet? current = _currentPlanet;
    final OrbitPlanet? target = _nextPlanet;
    if (current == null || target == null) return;
    if (_tutorialVisible) {
      _tutorialVisible = false;
      _tutorialDone = true;
      onTutorialCompleted?.call();
    }
    _player = _orbitPoint(current, _playerAngle);
    _launchStart = _player;
    _launchDirection = _tangent(_playerAngle, current.spinDirection);
    _flightSpeed = GameConfig.launchSpeedAt(_score) * _scale;
    if (_score ~/ (GameConfig.zoneLength * GameConfig.zoneCount) > 0) {
      _flightSpeed = math.min(
        GameConfig.maximumLaunchSpeed * _scale,
        _flightSpeed + (_score ~/ (GameConfig.zoneLength * GameConfig.zoneCount)) * 16 * _scale,
      ).toDouble();
    }
    _flightDistance = 0;
    _flightElapsed = 0;
    _phase = RunPhase.flying;
    _visiblePerfect = false;
    onLaunch?.call();
    _emitBurst(_player.x, _player.y, 0xFFB6F5FF, 7, 90);
    _publishHud(force: true);
  }

  void pauseRun() {
    if (_phase == RunPhase.gameOver) return;
    _paused = true;
    _phaseBeforePause = _phase;
    _phase = RunPhase.paused;
    _publishHud(force: true);
  }

  void resumeRun() {
    if (!_paused) return;
    _paused = false;
    _phase = _phaseBeforePause == RunPhase.paused ? RunPhase.ready : _phaseBeforePause;
    _publishHud(force: true);
  }

  void restart() {
    if (_phase != RunPhase.gameOver && _phase != RunPhase.paused) return;
    _runNumber++;
    _startNewRun(firstRun: false);
  }

  /// A rewarded continuation resumes the pending run without recording a
  /// second run. Finishing or replaying later records exactly one run result.
  bool revive() {
    if (_phase != RunPhase.gameOver || _finalized ||
        _revivesUsed >= GameConfig.rewardedRevivesPerRun) {
      return false;
    }
    _revivesUsed++;
    _phase = RunPhase.ready;
    _deathCause = null;
    _deathLine = '';
    _combo = 0;
    _fever = false;
    _feverSeconds = 0;
    _slowMotionSeconds = 0;
    _waitSeconds = 0;
    _dangerY = (_currentPlanet?.y ?? _player.y) + _height * 1.2;
    final OrbitPlanet? current = _currentPlanet;
    if (current != null) {
      _playerAngle = _idealAngleForDirection(current.spinDirection);
      _player = _orbitPoint(current, _playerAngle);
    }
    _message = AppStrings(languageCode).text('revive_message');
    _messageSeconds = 1.4;
    _shakeSeconds = 0.14;
    _shakePower = 5 * _scale;
    _publishHud(force: true);
    return true;
  }

  void finalizeRun({DeathCause? cause}) {
    if (_finalized || !_runStarted) return;
    if (cause != null && _phase != RunPhase.gameOver) {
      _deathCause = cause;
      _deathLine = _randomDeathLine(_random);
      _phase = RunPhase.gameOver;
    }
    if (_phase != RunPhase.gameOver) return;
    _finalized = true;
    final RunResult result = RunResult(
      score: _score,
      duration: Duration(milliseconds: (_runElapsed * 1000).round()),
      cause: _deathCause ?? DeathCause.missedOrbit,
      coins: _runCoins,
      gems: _runGems,
      perfects: _perfects,
      maxCombo: _maxCombo,
      isDailyChallenge: isDailyChallenge,
      runNumber: _runNumber,
    );
    onRunEnded?.call(result);
    _publishHud(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized || _paused || _phase == RunPhase.paused) return;
    final double delta = dt.clamp(0, 0.06).toDouble();
    _elapsed += delta;
    if (_phase != RunPhase.gameOver) _runElapsed += delta;
    if (_fever) {
      _feverSeconds = math.max(0, _feverSeconds - delta).toDouble();
      if (_feverSeconds <= 0) {
        _fever = false;
        onZoneChanged?.call(_zone, false);
      }
    }
    if (_slowMotionSeconds > 0) _slowMotionSeconds = math.max(0, _slowMotionSeconds - delta).toDouble();
    if (_perfectFlashSeconds > 0) _perfectFlashSeconds = math.max(0, _perfectFlashSeconds - delta).toDouble();
    if (_shakeSeconds > 0) _shakeSeconds = math.max(0, _shakeSeconds - delta).toDouble();
    if (_messageSeconds > 0) _messageSeconds = math.max(0, _messageSeconds - delta).toDouble();
    _updateParticles(delta);

    if (_phase == RunPhase.ready) {
      _updateReady(delta);
    } else if (_phase == RunPhase.flying) {
      _updateFlight(delta);
    }
    _updateCamera(delta);
    _planets.removeWhere((OrbitPlanet planet) =>
        !identical(planet, _currentPlanet) &&
        !identical(planet, _nextPlanet) &&
        planet.y - _cameraY > _height + 320 * _scale);
    _hudTimer += delta;
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  void _updateReady(double dt) {
    final OrbitPlanet? current = _currentPlanet;
    final OrbitPlanet? next = _nextPlanet;
    if (current == null) return;
    current.updateMotion(_elapsed, dt);
    next?.updateMotion(_elapsed, dt);
    _playerAngle += current.spinSpeed * current.spinDirection * dt;
    _player = _orbitPoint(current, _playerAngle);
    _waitSeconds += dt;
    _dangerY -= GameConfig.dangerRisePixelsPerSecond * _scale * dt;
    if (_waitSeconds >= GameConfig.maximumOrbitWaitSeconds) {
      _consumeShieldOrDie(DeathCause.waitedTooLong);
      return;
    }
    if (_dangerY <= _player.y + 4 * _scale) {
      _consumeShieldOrDie(DeathCause.dangerZone);
    }
  }

  void _updateFlight(double dt) {
    final OrbitPlanet? target = _nextPlanet;
    if (target == null) {
      _die(DeathCause.missedOrbit);
      return;
    }
    target.updateMotion(_elapsed, dt);
    final double slowScale = _slowMotionSeconds > 0 && !reducedMotion
        ? GameConfig.nearMissSlowMotionScale
        : 1;
    final double localDt = dt * slowScale;
    _flightDistance += _flightSpeed * localDt;
    _flightElapsed += localDt;
    _dangerY -= GameConfig.dangerRisePixelsPerSecond * _scale * dt;
    _player = _launchStart + _launchDirection * _flightDistance;
    _trailPositions.addFirst(Offset(_player.x, _player.y));
    while (_trailPositions.length > 18) {
      _trailPositions.removeLast();
    }
    _collectPickups();

    final Vec2 relative = Vec2(target.x - _launchStart.x, target.y - _launchStart.y);
    final double along = relative.dot(_launchDirection);
    final Vec2 lateral = relative - _launchDirection * along;
    final double perpendicular = lateral.length;
    final double orbitRadius = target.orbitRadius;
    final double laneWidth = math.min(
      orbitRadius - 3 * _scale,
      orbitRadius * 0.72 + _effectiveLandingWindow() * 0.44,
    ).toDouble();
    if (perpendicular <= laneWidth && along > 0) {
      final double inside = math.sqrt(math.max(0, orbitRadius * orbitRadius - perpendicular * perpendicular));
      final double entryDistance = along - inside;
      if (entryDistance > 0 && _flightDistance >= entryDistance) {
        final Vec2 impact = _launchStart + _launchDirection * entryDistance;
        final double impactAngle = math.atan2(impact.y - target.y, impact.x - target.x);
        if (target.isSpikedAt(impactAngle)) {
          _consumeShieldOrDie(DeathCause.spikes);
          return;
        }
        _player = impact;
        _landOn(target, impactAngle);
        return;
      }
    } else if (perpendicular <= laneWidth + 25 * _scale && along > 0) {
      _slowMotionSeconds = GameConfig.nearMissSlowMotionSeconds;
    }

    if (_flightDistance > 1500 * _scale || _flightElapsed > 2.9) {
      _die(DeathCause.missedOrbit);
      return;
    }
    if (_player.y < target.y - 420 * _scale ||
        (_player.x < -100 * _scale || _player.x > _width + 100 * _scale)) {
      _die(DeathCause.missedOrbit);
    }
  }

  void _collectPickups() {
    for (final _Pickup pickup in _pickups) {
      if (pickup.collected) continue;
      final double dx = pickup.x - _player.x;
      final double dy = pickup.y - _player.y;
      final double magnet = pickup.kind == PickupKind.coin ? _magnetRadius() : 0;
      final double range = (pickup.kind == PickupKind.coin ? 18 : 17) * _scale + magnet;
      if (dx * dx + dy * dy > range * range) continue;
      pickup.collected = true;
      if (pickup.kind == PickupKind.coin) {
        final int base = 1;
        final int earned = ScoreRules.applyMultiplier(base, _combo, fever: _fever);
        _runCoins += earned;
        _emitBurst(pickup.x, pickup.y, 0xFFFFD76B, 7, 60);
      } else {
        _runGems += 1;
        _emitBurst(pickup.x, pickup.y, 0xFFB990FF, 13, 105);
      }
      onCoinCollected?.call(pickup.kind);
    }
  }

  void _landOn(OrbitPlanet planet, double landingAngle) {
    final double angleDistance = _wrapAngle(_playerAngle - _idealLaunchAngle).abs();
    final double perfectWindow = _fever
        ? GameConfig.feverPerfectAngleWindow
        : GameConfig.perfectAngleWindow;
    final bool perfect = ScoreRules.isPerfect(angleDistance, window: perfectWindow);
    _score = ScoreRules.scoreAfterLanding(_score);
    _combo = ScoreRules.comboAfterLanding(_combo, perfect: perfect);
    _maxCombo = math.max(_maxCombo, _combo).toInt();
    if (perfect) {
      _perfects++;
      _visiblePerfect = true;
      _perfectFlashSeconds = reducedMotion ? 0.45 : 0.9;
    } else {
      _visiblePerfect = false;
    }
    final int baseReward = GameConfig.landingCoins + (perfect ? GameConfig.perfectBonusCoins : 0);
    _runCoins += ScoreRules.applyMultiplier(baseReward, _combo, fever: _fever);

    planet.orbitRadius = planet.radius + GameConfig.orbitGap * _scale;
    if (planet.shrinking) {
      planet.shrinkRate = (3.5 + _score * 0.08) * _scale;
    }
    _currentPlanet = planet;
    _nextPlanet = null;
    _playerAngle = landingAngle;
    _player = _orbitPoint(planet, _playerAngle);
    _waitSeconds = 0;
    _phase = RunPhase.ready;
    _flightDistance = 0;
    _flightElapsed = 0;
    _trailPositions.clear();
    _emitBurst(_player.x, _player.y, perfect ? 0xFFFFDF75 : 0xFF89E8FF, perfect ? 24 : 16, perfect ? 170 : 115);
    _shakeSeconds = reducedMotion ? 0 : perfect ? 0.23 : 0.13;
    _shakePower = (perfect ? 5 : 3) * _scale;

    if (_combo >= GameConfig.feverPerfectsRequired &&
        _combo % GameConfig.feverPerfectsRequired == 0 && !_fever) {
      final int feverLevel = isDailyChallenge ? 0 : (upgradeLevels['feverTime'] ?? 0);
      _fever = true;
      _feverSeconds = GameConfig.feverDuration.inMilliseconds / 1000 +
          feverLevel * GameConfig.feverSecondsPerLevel;
      onFeverStarted?.call();
      onZoneChanged?.call(_zone, true);
      _emitBurst(_player.x, _player.y, 0xFFFF8CFF, 44, 230);
    }

    final int newZone = GameConfig.zoneIndexAt(_score);
    if (newZone != _zone) {
      _zone = newZone;
      onZoneChanged?.call(_zone, _fever);
      _emitBurst(_player.x, _player.y, GameConfig.zones[_zone].accentArgb, 26, 190);
    }
    onLanding?.call(perfect, _combo);
    _makeNextPlanet();
    _publishHud(force: true);
  }

  void _consumeShieldOrDie(DeathCause cause) {
    if (_shieldsRemaining > 0) {
      _shieldsRemaining--;
      _message = AppStrings(languageCode).text('shield_message');
      _messageSeconds = 1.25;
      _waitSeconds = 0;
      _dangerY = (_currentPlanet?.y ?? _player.y) + _height * 1.15;
      _combo = 0;
      _fever = false;
      _feverSeconds = 0;
      final OrbitPlanet? current = _currentPlanet;
      if (current != null) {
        _playerAngle = _idealAngleForDirection(current.spinDirection);
        _player = _orbitPoint(current, _playerAngle);
      }
      _phase = RunPhase.ready;
      _nextPlanet = null;
      _makeNextPlanet();
      _emitBurst(_player.x, _player.y, 0xFF82F5FF, 24, 150);
      onShieldSaved?.call();
      _publishHud(force: true);
      return;
    }
    _die(cause);
  }

  void _die(DeathCause cause) {
    if (_phase == RunPhase.gameOver || _finalized) return;
    _phase = RunPhase.gameOver;
    _deathCause = cause;
    final StableRandom lineRandom = StableRandom(initialSeed ^ _score ^ _runNumber * 31);
    _deathLine = _randomDeathLine(lineRandom);
    onDeath?.call();
    _shakeSeconds = reducedMotion ? 0 : 0.36;
    _shakePower = 9 * _scale;
    _emitBurst(_player.x, _player.y, 0xFFFF7797, 28, 210);
    _publishHud(force: true);
  }

  String _randomDeathLine(StableRandom random) {
    final List<String> translated = AppStrings(languageCode).translatedDeathLines;
    final List<String> lines = translated.isEmpty ? _deathLines : translated;
    return lines[random.nextInt(lines.length)];
  }

  void _updateCamera(double dt) {
    final double targetCamera = _player.y - _height * 0.62;
    if (targetCamera < _cameraY) {
      final double snap = reducedMotion ? 1 : math.min(1, dt * 8).toDouble();
      _cameraY += (targetCamera - _cameraY) * snap;
    }
  }

  void _updateParticles(double dt) {
    for (final ParticleState particle in _particles) {
      particle.life -= dt;
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vy += 60 * _scale * dt;
      particle.radius *= math.max(0.92, 1 - dt * 0.45).toDouble();
    }
    _particles.removeWhere((ParticleState particle) => particle.life <= 0);
  }

  void _emitBurst(double x, double y, int color, int amount, double force) {
    final int allowed = math.min(amount, GameConfig.maximumParticles - _particles.length).toInt();
    if (allowed <= 0) return;
    for (int i = 0; i < allowed; i++) {
      final double angle = _random.between(0, math.pi * 2);
      final double speed = _random.between(force * 0.25, force) * _scale;
      _particles.add(ParticleState(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        radius: _random.between(1.4, 3.6) * _scale,
        life: _random.between(0.28, 0.72),
        colorArgb: color,
        spark: i % 4 == 0,
      ));
    }
  }

  void _publishHud({bool force = false}) {
    if (!_initialized && !force) return;
    final RunHudState current = hud.value;
    final RunHudState next = RunHudState(
      phase: _phase,
      score: _score,
      combo: _combo,
      multiplier: ScoreRules.multiplierForCombo(_combo),
      runCoins: _runCoins,
      runGems: _runGems,
      feverSeconds: _feverSeconds,
      isFever: _fever,
      isDailyChallenge: isDailyChallenge,
      tutorialVisible: _tutorialVisible,
      perfectFlash: _perfectFlashSeconds,
      zoneIndex: _zone,
      deathCause: _deathCause,
      deathLine: _deathLine,
      runSeconds: _runElapsed,
      finalized: _finalized,
      shieldAvailable: _shieldsRemaining > 0,
      reviveAvailable: _revivesUsed < GameConfig.rewardedRevivesPerRun && !_finalized,
    );
    if (force || current.phase != next.phase || current.score != next.score ||
        current.combo != next.combo || current.runCoins != next.runCoins ||
        current.runGems != next.runGems || current.isFever != next.isFever ||
        current.feverSeconds != next.feverSeconds || current.tutorialVisible != next.tutorialVisible ||
        current.finalized != next.finalized || current.deathLine != next.deathLine) {
      hud.value = next;
    }
  }

  double _idealAngleForDirection(int direction) => direction > 0 ? math.pi : 0;

  static double _wrapAngle(double value) {
    double angle = value;
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_width <= 0 || _height <= 0) return;
    final ZonePalette palette = GameConfig.zones[_zone];
    final Offset shake = _shakeOffset;
    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    _drawBackground(canvas, palette);
    _drawWorldPlanets(canvas, palette);
    _drawPickups(canvas);
    _drawDanger(canvas);
    _drawTrail(canvas);
    _drawPlayer(canvas);
    _drawParticles(canvas);
    _drawWorldMessage(canvas);
    canvas.restore();
  }

  Offset get _shakeOffset {
    if (reducedMotion || _shakeSeconds <= 0) return Offset.zero;
    final double strength = _shakePower * (_shakeSeconds / 0.36);
    return Offset(
      math.sin(_elapsed * 67) * strength,
      math.cos(_elapsed * 53) * strength * 0.72,
    );
  }

  void _drawBackground(Canvas canvas, ZonePalette palette) {
    final Rect bounds = Rect.fromLTWH(0, 0, _width, _height);
    final Color background = Color(palette.backgroundArgb);
    final Color accent = Color(palette.accentArgb);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(background, accent, _fever ? 0.14 : 0.035)!,
            background,
            Color.lerp(background, const Color(0xFF03040B), 0.5)!,
          ],
        ).createShader(bounds),
    );
    final Offset nebula = Offset(_screenCenterX, _height * 0.42);
    canvas.drawCircle(
      nebula,
      _width * 0.7,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[accent.withValues(alpha: _fever ? 0.13 : 0.07), Colors.transparent],
        ).createShader(Rect.fromCircle(center: nebula, radius: _width * 0.7)),
    );
    for (final _Star star in _stars) {
      final double y = (star.y * _height + _cameraY * star.parallax) % _height;
      final double twinkle = 0.38 + 0.62 * (0.5 + 0.5 * math.sin(_elapsed * 1.7 + star.twinkle));
      final double radius = star.radius * _scale;
      canvas.drawCircle(
        Offset(star.x * _width, y < 0 ? y + _height : y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: twinkle * 0.62),
      );
    }
    if (_fever && !reducedMotion) {
      for (int i = 0; i < 4; i++) {
        final double y = (_elapsed * (36 + i * 7) + i * _height * 0.27) % _height;
        final double x = (_screenCenterX + math.sin(_elapsed * 0.6 + i) * _width * 0.38);
        canvas.drawCircle(
          Offset(x, y),
          (2 + i % 2).toDouble() * _scale,
          Paint()..color = const Color(0xFFFFD875).withValues(alpha: 0.6),
        );
      }
    }
  }

  void _drawWorldPlanets(Canvas canvas, ZonePalette palette) {
    final List<OrbitPlanet> visible = _planets.where((OrbitPlanet planet) {
      final double y = planet.y - _cameraY;
      return y > -planet.radius * 3 && y < _height + planet.radius * 3;
    }).toList(growable: false);
    for (final OrbitPlanet planet in visible) {
      final Offset center = Offset(planet.x, planet.y - _cameraY);
      _drawOrbit(canvas, planet, center);
      _drawPlanet(canvas, planet, center, palette);
    }
  }

  void _drawOrbit(Canvas canvas, OrbitPlanet planet, Offset center) {
    final double radius = planet.orbitRadius;
    final Paint halo = Paint()
      ..color = const Color(0xFF9EEBFF).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * _scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * _scale);
    canvas.drawCircle(center, radius, halo);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * _scale,
    );
    if (planet.hasSpikes) {
      for (final double angle in planet.spikeAngles) {
        final Offset start = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 2 * _scale);
        final Offset end = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 9 * _scale);
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = const Color(0xFFFF647C)
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3.6 * _scale
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * _scale),
        );
      }
    }
    if (planet == _nextPlanet) {
      canvas.drawCircle(
        center,
        radius + 12 * _scale + math.sin(_elapsed * 2) * 2 * _scale,
        Paint()
          ..color = Color(GameConfig.zones[_zone].accentArgb).withValues(alpha: 0.09)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * _scale,
      );
    }
  }

  void _drawPlanet(Canvas canvas, OrbitPlanet planet, Offset center, ZonePalette palette) {
    final double radius = planet.radius;
    final ThemeDefinition chosenTheme = CosmeticCatalog.themeById(theme);
    final Color primary = Color.lerp(
      Color(palette.accentArgb), Color(chosenTheme.accentArgb), 0.24,
    )!;
    final Color secondary = Color.lerp(
      Color(palette.secondaryArgb), Color(chosenTheme.secondaryArgb), 0.18,
    )!;
    final Color bodyColor = Color.lerp(primary, secondary, (planet.seed % 100) / 100) ?? primary;
    canvas.drawCircle(
      center,
      radius + 9 * _scale,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * _scale),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.48),
          radius: 1,
          colors: <Color>[
            Color.lerp(Colors.white, bodyColor, 0.2)!,
            bodyColor,
            Color.lerp(bodyColor, const Color(0xFF07101D), 0.45)!,
          ],
          stops: const <double>[0, 0.52, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final int spots = 2 + planet.seed.abs() % 3;
    for (int i = 0; i < spots; i++) {
      final double x = (((planet.seed >> (i * 3)) & 0xFF) / 255 - 0.5) * 1.1;
      final double y = (((planet.seed >> (i * 5 + 1)) & 0xFF) / 255 - 0.5) * 0.9;
      final Offset spot = center + Offset(x * radius, y * radius);
      canvas.drawCircle(
        spot,
        radius * (0.12 + 0.05 * i),
        Paint()..color = Colors.white.withValues(alpha: 0.07),
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.68),
      -2.65,
      1.45,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * _scale,
    );
  }

  void _drawPickups(Canvas canvas) {
    for (final _Pickup pickup in _pickups) {
      if (pickup.collected) continue;
      final Offset center = Offset(pickup.x, pickup.y - _cameraY);
      if (pickup.kind == PickupKind.coin) {
        final double pulse = 1 + math.sin(_elapsed * 4 + pickup.x * 0.1) * 0.09;
        canvas.drawCircle(
          center,
          9 * _scale * pulse,
          Paint()
            ..color = const Color(0xFFFFD66F).withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * _scale),
        );
        canvas.drawCircle(center, 6.2 * _scale * pulse, Paint()..color = const Color(0xFFFFD66F));
        canvas.drawCircle(
          center,
          3.4 * _scale * pulse,
          Paint()
            ..color = const Color(0xFFFFF1B4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * _scale,
        );
      } else {
        final double pulse = 1 + math.sin(_elapsed * 5) * 0.11;
        final Path gem = Path()
          ..moveTo(center.dx, center.dy - 10 * _scale * pulse)
          ..lineTo(center.dx + 7 * _scale * pulse, center.dy)
          ..lineTo(center.dx, center.dy + 10 * _scale * pulse)
          ..lineTo(center.dx - 7 * _scale * pulse, center.dy)
          ..close();
        canvas.drawPath(
          gem,
          Paint()
            ..color = const Color(0xFFBF9AFF).withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * _scale),
        );
        canvas.drawPath(gem, Paint()..color = const Color(0xFFB990FF));
        canvas.drawPath(
          gem,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * _scale,
        );
      }
    }
  }

  void _drawDanger(Canvas canvas) {
    final double y = _dangerY - _cameraY;
    if (y < -25 * _scale || y > _height + 60 * _scale) return;
    final Paint glow = Paint()
      ..color = const Color(0xFFFF4F7B).withValues(alpha: 0.2)
      ..strokeWidth = 11 * _scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * _scale);
    canvas.drawLine(Offset(0, y), Offset(_width, y), glow);
    canvas.drawLine(
      Offset(0, y),
      Offset(_width, y),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0x00FF527B), Color(0xFFFF527B), Color(0x00FF527B)],
        ).createShader(Rect.fromLTWH(0, y, _width, 1)),
    );
    final TextPainter label = TextPainter(
      text: TextSpan(
        text: AppStrings(languageCode).text('danger_zone'),
        style: const TextStyle(color: Color(0xFFFF829A), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(15, y - 19 * _scale));
  }

  void _drawTrail(Canvas canvas) {
    if (_trailPositions.length < 2) return;
    final TrailDefinition trailDefinition = CosmeticCatalog.trailById(trail);
    final Color trailColor = Color(trailDefinition.colorArgb);
    final List<Offset> points = _trailPositions.toList(growable: false);
    for (int i = points.length - 1; i >= 0; i--) {
      final double amount = 1 - i / points.length;
      final Offset point = Offset(points[i].dx, points[i].dy - _cameraY);
      canvas.drawCircle(
        point,
        (2.2 + amount * 4.5) * _scale,
        Paint()
          ..color = trailColor.withValues(alpha: amount * (_fever ? 0.72 : 0.45))
          ..maskFilter = amount > 0.7 ? MaskFilter.blur(BlurStyle.normal, 4 * _scale) : null,
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    final Offset center = Offset(_player.x, _player.y - _cameraY);
    if (_fever) {
      final double pulse = 1 + math.sin(_elapsed * 10) * 0.1;
      canvas.drawCircle(
        center,
        23 * _scale * pulse,
        Paint()
          ..color = const Color(0xFFFF8EF7).withValues(alpha: 0.24)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * _scale),
      );
    }
    final SkinDefinition definition = CosmeticCatalog.skinById(skin);
    final double squash = _phase == RunPhase.ready
        ? 1 + math.sin(_elapsed * 4.5) * 0.035
        : _phase == RunPhase.flying
            ? 1.12
            : 1;
    final double radius = GameConfig.playerRadius * _scale;
    final Rect bodyBounds = Rect.fromCenter(
      center: center,
      width: radius * 2.05 * squash,
      height: radius * 1.8 / squash,
    );
    final Color body = Color(definition.colorArgb);
    canvas.drawCircle(
      center,
      radius * 1.6,
      Paint()
        ..color = body.withValues(alpha: 0.24)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 11 * _scale),
    );
    if (definition.shape == 'star') {
      final Path star = _starPath(center, radius * 1.45);
      canvas.drawPath(star, Paint()..color = body);
      canvas.drawPath(
        star,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[Colors.white.withValues(alpha: 0.75), Colors.transparent],
          ).createShader(bodyBounds),
      );
    } else if (definition.shape == 'squircle') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyBounds, Radius.circular(radius * 0.7)),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: <Color>[Color.lerp(Colors.white, body, 0.3)!, body, Color.lerp(body, Colors.black, 0.12)!],
          ).createShader(bodyBounds),
      );
    } else if (definition.shape == 'droplet') {
      final Path drop = Path()
        ..moveTo(center.dx, center.dy - radius * 1.1)
        ..cubicTo(center.dx + radius * 1.65, center.dy - radius * 0.8,
            center.dx + radius * 1.1, center.dy + radius * 1.2,
            center.dx, center.dy + radius * 1.0)
        ..cubicTo(center.dx - radius * 1.1, center.dy + radius * 1.2,
            center.dx - radius * 1.65, center.dy - radius * 0.8,
            center.dx, center.dy - radius * 1.1)
        ..close();
      canvas.drawPath(drop, Paint()..color = body);
    } else {
      canvas.drawOval(
        bodyBounds,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.42, -0.52),
            colors: <Color>[Color.lerp(Colors.white, body, 0.25)!, body, Color.lerp(body, Colors.black, 0.12)!],
            stops: const <double>[0, 0.54, 1],
          ).createShader(bodyBounds),
      );
    }
    _drawFace(canvas, center, radius, definition.face);
    _drawAccessory(canvas, center, radius, definition.accessory);
  }

  Path _starPath(Offset center, double radius) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final double r = i.isEven ? radius : radius * 0.72;
      final Offset point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawFace(Canvas canvas, Offset center, double radius, String face) {
    final double eyeY = center.dy - radius * 0.03;
    final double eyeOffset = radius * 0.37;
    final Paint eyeWhite = Paint()..color = const Color(0xFFF8FDFF);
    final Paint pupil = Paint()..color = const Color(0xFF182135);
    if (face == 'cyclops') {
      canvas.drawCircle(Offset(center.dx, eyeY), radius * 0.24, eyeWhite);
      canvas.drawCircle(Offset(center.dx + radius * 0.045, eyeY), radius * 0.115, pupil);
    } else if (face == 'sleepy') {
      for (final double side in <double>[-1, 1]) {
        canvas.drawLine(
          Offset(center.dx + side * eyeOffset - radius * 0.12, eyeY),
          Offset(center.dx + side * eyeOffset + radius * 0.12, eyeY + radius * 0.04),
          Paint()
            ..color = const Color(0xFF25304A)
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.1 * _scale,
        );
      }
    } else {
      canvas.drawCircle(Offset(center.dx - eyeOffset, eyeY), radius * 0.21, eyeWhite);
      canvas.drawCircle(Offset(center.dx - eyeOffset + radius * 0.04, eyeY), radius * 0.1, pupil);
      if (face == 'wink') {
        canvas.drawLine(
          Offset(center.dx + eyeOffset - radius * 0.13, eyeY),
          Offset(center.dx + eyeOffset + radius * 0.13, eyeY + radius * 0.025),
          Paint()
            ..color = const Color(0xFF25304A)
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.1 * _scale,
        );
      } else {
        canvas.drawCircle(Offset(center.dx + eyeOffset, eyeY), radius * 0.21, eyeWhite);
        canvas.drawCircle(Offset(center.dx + eyeOffset + radius * 0.04, eyeY), radius * 0.1, pupil);
      }
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.22),
        width: radius * 0.52,
        height: radius * 0.34,
      ),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFF25304A)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6 * _scale,
    );
  }

  void _drawAccessory(Canvas canvas, Offset center, double radius, String accessory) {
    final Paint gold = Paint()
      ..color = const Color(0xFFFFD46F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * _scale;
    switch (accessory) {
      case 'halo':
      case 'moon':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.82), width: radius * 1.2, height: radius * 0.34),
          gold,
        );
      case 'crown':
        final Path crown = Path()
          ..moveTo(center.dx - radius * 0.62, center.dy - radius * 0.72)
          ..lineTo(center.dx - radius * 0.45, center.dy - radius * 1.25)
          ..lineTo(center.dx, center.dy - radius * 0.88)
          ..lineTo(center.dx + radius * 0.42, center.dy - radius * 1.25)
          ..lineTo(center.dx + radius * 0.63, center.dy - radius * 0.72)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD46F));
      case 'antenna':
        canvas.drawLine(Offset(center.dx, center.dy - radius * 0.7), Offset(center.dx, center.dy - radius * 1.28), gold);
        canvas.drawCircle(Offset(center.dx, center.dy - radius * 1.33), radius * 0.11, Paint()..color = const Color(0xFFFF8DAB));
      case 'visor':
      case 'helmet':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.12), width: radius * 1.65, height: radius * 1.18),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.62)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * _scale,
        );
      case 'bow':
        canvas.drawCircle(Offset(center.dx + radius * 0.65, center.dy - radius * 0.68), radius * 0.17, Paint()..color = const Color(0xFFFF8CB8));
        canvas.drawCircle(Offset(center.dx + radius * 0.92, center.dy - radius * 0.68), radius * 0.17, Paint()..color = const Color(0xFFFF8CB8));
        canvas.drawCircle(Offset(center.dx + radius * 0.79, center.dy - radius * 0.68), radius * 0.11, Paint()..color = const Color(0xFFFFD46F));
      case 'leaf':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.92), width: radius * 0.34, height: radius * 0.55),
          Paint()..color = const Color(0xFF83E57E),
        );
      case 'scarf':
        canvas.drawLine(
          Offset(center.dx - radius * 0.78, center.dy + radius * 0.42),
          Offset(center.dx + radius * 0.75, center.dy + radius * 0.42),
          Paint()
            ..color = const Color(0xFFFF708E)
            ..strokeWidth = 3 * _scale
            ..strokeCap = StrokeCap.round,
        );
      case 'ring':
        canvas.drawCircle(
          center,
          radius * 1.22,
          Paint()
            ..color = const Color(0xFFB7A6FF).withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * _scale,
        );
      default:
        // The plain skin intentionally has no accessory.
        break;
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final ParticleState particle in _particles) {
      final double alpha = particle.life.clamp(0, 1).toDouble();
      final Offset center = Offset(particle.x, particle.y - _cameraY);
      final Color color = Color(particle.colorArgb).withValues(alpha: alpha);
      if (particle.spark) {
        final double length = particle.radius * 3.3;
        canvas.drawLine(
          center,
          center - Vec2(particle.vx, particle.vy).normalized().offset * length,
          Paint()
            ..color = color
            ..strokeCap = StrokeCap.round
            ..strokeWidth = particle.radius * 0.75,
        );
      } else {
        canvas.drawCircle(
          center,
          particle.radius,
          Paint()
            ..color = color
            ..maskFilter = particle.radius > 2.2 * _scale && !reducedMotion
                ? MaskFilter.blur(BlurStyle.normal, 2.2 * _scale)
                : null,
        );
      }
    }
  }

  void _drawWorldMessage(Canvas canvas) {
    if (_tutorialVisible && _phase == RunPhase.ready) {
      final TextPainter hint = TextPainter(
        text: TextSpan(
          text: AppStrings(languageCode).text('tap_short'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.94),
            fontSize: 17 * _scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            shadows: const <Shadow>[Shadow(color: Color(0xFF83EFFF), blurRadius: 12)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset(_player.x - hint.width / 2, _player.y - _cameraY - 55 * _scale));
      canvas.drawLine(
        Offset(_player.x, _player.y - _cameraY - 30 * _scale),
        Offset(_player.x, _player.y - _cameraY - 20 * _scale),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.3 * _scale
          ..strokeCap = StrokeCap.round,
      );
    }
    if (_perfectFlashSeconds > 0 && _visiblePerfect) {
      final double alpha = (_perfectFlashSeconds / 0.9).clamp(0, 1).toDouble();
      final TextPainter perfect = TextPainter(
        text: TextSpan(
          text: AppStrings(languageCode).text('perfect_flash'),
          style: TextStyle(
            color: const Color(0xFFFFDF77).withValues(alpha: alpha),
            fontSize: (20 + (1 - alpha) * 4) * _scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            shadows: const <Shadow>[Shadow(color: Color(0xFFFFC56B), blurRadius: 14)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      perfect.paint(canvas, Offset(_player.x - perfect.width / 2, _player.y - _cameraY - 70 * _scale));
    }
    if (_messageSeconds > 0) {
      final TextPainter message = TextPainter(
        text: TextSpan(
          text: _message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: math.min(1, _messageSeconds + 0.2).toDouble()),
            fontSize: 12 * _scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _width - 40);
      message.paint(canvas, Offset(_screenCenterX - message.width / 2, _height * 0.36));
    }
  }

  @override
  void onRemove() {
    hud.dispose();
    super.onRemove();
  }

  static const List<String> _deathLines = <String>[
    'The planet said “not today.”',
    'Gravity just filed a complaint.',
    'Your blob took the scenic route. Too scenic.',
    'Orbit status: emotionally complicated.',
    'The landing was almost a high-five.',
    'Space called. It wants its blob back.',
    'The planet blinked. Rude timing.',
    'A brave launch. A very short sequel.',
    'You have been gently yeeted.',
    'That orbit had commitment issues.',
    'Cosmic soup: one, blob: zero.',
    'The stars are pretending they saw nothing.',
    'A tiny detour into the big dark.',
    'The planet was just out of snack range.',
    'Your blob is now a shooting star. Briefly.',
    'The universe has a slippery floor.',
    'Orbit math is a little dramatic today.',
    'The next planet was playing hard to get.',
    'Your trajectory has left the group chat.',
    'That was a very confident almost.',
    'The blob has requested a tiny parachute.',
    'Space: surprisingly bad at catching.',
    'A graceful exit. Mostly.',
    'The planet needs to work on its welcome mat.',
    'Your blob found the off-screen shortcut.',
    'The stars voted for “one more try.”',
    'Orbit? More like or-bit-too-far.',
    'Gravity is a clingy ex.',
    'That spike was definitely not invited.',
    'The danger soup got a little too close.',
    'A+ launch. Needs a landing chapter.',
    'The cosmos says: boop, not today.',
    'Your blob is taking an unscheduled nap.',
    'That planet was a moving target. Suspicious.',
    'You almost made it. Space is petty.',
    'The orbit went out for milk and never came back.',
    'Even comets miss sometimes. You are in good company.',
    'The blob tried its best. The blob needs a map.',
    'The galaxy has a strict no-floors policy.',
    'A tiny blob, a giant whoops.',
    'That was a bold new definition of “landing.”',
    'The planet was not accepting visitors.',
    'Your orbit has been forwarded to management.',
    'The stars would clap, but they have no hands.',
    'The blob missed the memo about stopping.',
    'Space is 99.9% empty. You found the .1%.',
    'That landing zone was playing hide-and-seek.',
    'A beautiful flight, with an unexpected ending.',
    'The blob is fine. Its ego is in low orbit.',
    'The universe said “boing” and meant it.',
    'Your next run is already looking adorable.',
    'That was not a crash. It was a dramatic entrance.',
    'Cosmic soup has excellent timing.',
    'The planet was wearing its invisible cloak.',
    'The blob has gone to ask the moon for directions.',
    'You have unlocked the rare “almost” ending.',
    'Space is big. Your aim is getting bigger.',
    'This is why planets have safety rails.',
    'The blob is filing for orbit insurance.',
    'A valiant hop. The sequel is yours.',
  ];
}

class _Pickup {
  _Pickup(this.x, this.y, this.kind);
  final double x;
  final double y;
  final PickupKind kind;
  bool collected = false;
}

class _Star {
  const _Star({required this.x, required this.y, required this.radius, required this.twinkle, required this.parallax});

  final double x;
  final double y;
  final double radius;
  final double twinkle;
  final double parallax;
}

extension on Vec2 {
  Offset get offset => Offset(x, y);
}
