import 'dart:math' as math;

/// Minimal vector type keeps the rules layer independent from Flutter/Flame.
class Vec2 {
  const Vec2(this.x, this.y);

  final double x;
  final double y;

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scale) => Vec2(x * scale, y * scale);

  double get length => math.sqrt(x * x + y * y);

  double dot(Vec2 other) => x * other.x + y * other.y;

  Vec2 normalized() {
    final double magnitude = length;
    return magnitude == 0 ? const Vec2(0, 0) : Vec2(x / magnitude, y / magnitude);
  }
}

enum RunPhase { ready, flying, gameOver, paused }

enum DeathCause { missedOrbit, spikes, dangerZone, waitedTooLong, quit }

class RunResult {
  const RunResult({
    required this.score,
    required this.duration,
    required this.cause,
    required this.coins,
    required this.gems,
    required this.perfects,
    required this.maxCombo,
    required this.isDailyChallenge,
    this.runNumber = 0,
  });

  final int score;
  final Duration duration;
  final DeathCause cause;
  final int coins;
  final int gems;
  final int perfects;
  final int maxCombo;
  final bool isDailyChallenge;
  final int runNumber;
}

class ScoreRules {
  ScoreRules._();

  /// Score is planet count. A perfect affects the reward multiplier, not the
  /// score itself, so a normal landing never changes the meaning of the HUD.
  static int scoreAfterLanding(int score) => math.max(0, score).toInt() + 1;

  static bool isPerfect(double angularDistance, {double window = 0.15}) =>
      angularDistance.abs() <= window;

  static int comboAfterLanding(int previousCombo, {required bool perfect}) =>
      perfect ? math.max(0, previousCombo).toInt() + 1 : 0;

  static int multiplierForCombo(int combo) =>
      combo <= 0 ? 1 : math.min(10, 1 + (combo ~/ 3)).toInt();

  static int applyMultiplier(int baseCoins, int combo, {bool fever = false}) {
    final int feverFactor = fever ? 2 : 1;
    return math.max(0, baseCoins).toInt() * multiplierForCombo(combo) * feverFactor;
  }
}

class OrbitPlanet {
  OrbitPlanet({
    required this.x,
    required this.y,
    required this.radius,
    required this.orbitRadius,
    required this.spinSpeed,
    required this.spinDirection,
    required this.phase,
    required this.seed,
    this.motionAmplitude = 0,
    this.motionFrequency = 0,
    this.moving = false,
    this.hasSpikes = false,
    this.spikeAngles = const <double>[],
    this.shrinking = false,
  }) : baseX = x,
       baseY = y;

  double x;
  double y;
  final double baseX;
  final double baseY;
  double radius;
  double orbitRadius;
  double spinSpeed;
  int spinDirection;
  double phase;
  final int seed;
  double motionAmplitude;
  double motionFrequency;
  bool moving;
  bool hasSpikes;
  List<double> spikeAngles;
  bool shrinking;
  double shrinkRate = 0;

  void updateMotion(double elapsedSeconds, double deltaSeconds) {
    if (moving) {
      x = baseX + math.sin(elapsedSeconds * motionFrequency + phase) * motionAmplitude;
      y = baseY + math.sin(elapsedSeconds * motionFrequency * 0.61 + phase) * 5;
    }
    if (shrinking) {
      final double gap = orbitRadius - radius;
      radius = math.max(16, radius - shrinkRate * deltaSeconds).toDouble();
      orbitRadius = radius + gap;
    }
  }

  bool isSpikedAt(double angle) {
    if (!hasSpikes) return false;
    for (final double spikeAngle in spikeAngles) {
      final double delta = _wrapAngle(angle - spikeAngle);
      if (delta.abs() < 0.28) return true;
    }
    return false;
  }

  static double _wrapAngle(double value) {
    var angle = value;
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }
}

class ParticleState {
  ParticleState({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.life,
    required this.colorArgb,
    this.spark = false,
  });

  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double life;
  final int colorArgb;
  final bool spark;
}

class PickupState {
  const PickupState({
    required this.x,
    required this.y,
    required this.kind,
    this.collected = false,
  });

  final double x;
  final double y;
  final PickupKind kind;
  final bool collected;
}

enum PickupKind { coin, gem }

class RunHudState {
  const RunHudState({
    required this.phase,
    required this.score,
    required this.combo,
    required this.multiplier,
    required this.runCoins,
    required this.runGems,
    required this.feverSeconds,
    required this.isFever,
    required this.isDailyChallenge,
    required this.tutorialVisible,
    required this.perfectFlash,
    required this.zoneIndex,
    this.deathCause,
    this.deathLine = '',
    this.runSeconds = 0,
    this.finalized = false,
    this.shieldAvailable = false,
    this.reviveAvailable = false,
  });

  final RunPhase phase;
  final int score;
  final int combo;
  final int multiplier;
  final int runCoins;
  final int runGems;
  final double feverSeconds;
  final bool isFever;
  final bool isDailyChallenge;
  final bool tutorialVisible;
  final double perfectFlash;
  final int zoneIndex;
  final DeathCause? deathCause;
  final String deathLine;
  final double runSeconds;
  final bool finalized;
  final bool shieldAvailable;
  final bool reviveAvailable;
}
