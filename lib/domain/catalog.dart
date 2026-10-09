class SkinDefinition {
  const SkinDefinition({
    required this.id,
    required this.name,
    required this.shape,
    required this.face,
    required this.accessory,
    required this.colorArgb,
    this.coinCost = 0,
    this.gemCost = 0,
    this.achievementId,
  });

  final String id;
  final String name;
  final String shape;
  final String face;
  final String accessory;
  final int colorArgb;
  final int coinCost;
  final int gemCost;
  final String? achievementId;

  bool get isAchievementLocked => achievementId != null;
}

class TrailDefinition {
  const TrailDefinition({
    required this.id,
    required this.name,
    required this.colorArgb,
    required this.coinCost,
    this.achievementId,
  });

  final String id;
  final String name;
  final int colorArgb;
  final int coinCost;
  final String? achievementId;
}

class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.accentArgb,
    required this.secondaryArgb,
    required this.backgroundArgb,
    this.coinCost = 0,
    this.achievementId,
  });

  final String id;
  final String name;
  final int accentArgb;
  final int secondaryArgb;
  final int backgroundArgb;
  final int coinCost;
  final String? achievementId;
}

class CosmeticCatalog {
  CosmeticCatalog._();

  static const List<SkinDefinition> skins = <SkinDefinition>[
    SkinDefinition(id: 'comet', name: 'Comet', shape: 'round', face: 'smile', accessory: 'none', colorArgb: 0xFF74E8FF),
    SkinDefinition(id: 'mango', name: 'Mango', shape: 'round', face: 'wink', accessory: 'none', colorArgb: 0xFFFFBE68, coinCost: 250),
    SkinDefinition(id: 'mint', name: 'Mint Chip', shape: 'squircle', face: 'smile', accessory: 'none', colorArgb: 0xFF71F0C5, coinCost: 350),
    SkinDefinition(id: 'berry', name: 'Berry Pop', shape: 'round', face: 'cyclops', accessory: 'none', colorArgb: 0xFFFF72B8, coinCost: 450),
    SkinDefinition(id: 'pebble', name: 'Pebble', shape: 'squircle', face: 'sleepy', accessory: 'none', colorArgb: 0xFFB2B8D9, coinCost: 550),
    SkinDefinition(id: 'jelly', name: 'Jellybean', shape: 'droplet', face: 'smile', accessory: 'none', colorArgb: 0xFFA98CFF, coinCost: 650),
    SkinDefinition(id: 'sprout', name: 'Sprout', shape: 'round', face: 'wink', accessory: 'leaf', colorArgb: 0xFF9BEE7D, coinCost: 750),
    SkinDefinition(id: 'sunny', name: 'Sunny Side', shape: 'round', face: 'smile', accessory: 'halo', colorArgb: 0xFFFFDF64, coinCost: 900),
    SkinDefinition(id: 'puff', name: 'Puffball', shape: 'squircle', face: 'sleepy', accessory: 'bow', colorArgb: 0xFFFF9BA8, coinCost: 1050),
    SkinDefinition(id: 'orbit', name: 'Orbit', shape: 'round', face: 'cyclops', accessory: 'antenna', colorArgb: 0xFF68D8FF, coinCost: 1200),
    SkinDefinition(id: 'toast', name: 'Toast', shape: 'squircle', face: 'wink', accessory: 'none', colorArgb: 0xFFE5A978, coinCost: 1400),
    SkinDefinition(id: 'ghost', name: 'Ghostlight', shape: 'droplet', face: 'sleepy', accessory: 'halo', colorArgb: 0xFFDAD5FF, coinCost: 1600),
    SkinDefinition(id: 'pixel', name: 'Pixel', shape: 'squircle', face: 'cyclops', accessory: 'visor', colorArgb: 0xFF85FFA9, coinCost: 1850),
    SkinDefinition(id: 'boba', name: 'Boba', shape: 'round', face: 'smile', accessory: 'bow', colorArgb: 0xFFCA9BFF, coinCost: 2100),
    SkinDefinition(id: 'tangerine', name: 'Tangerine', shape: 'droplet', face: 'wink', accessory: 'leaf', colorArgb: 0xFFFF9162, coinCost: 2400),
    SkinDefinition(id: 'snowy', name: 'Snowy', shape: 'round', face: 'sleepy', accessory: 'scarf', colorArgb: 0xFFB1EDFF, coinCost: 2700),
    SkinDefinition(id: 'champion', name: 'Champion', shape: 'round', face: 'smile', accessory: 'crown', colorArgb: 0xFFFFD86E, achievementId: 'zone_2'),
    SkinDefinition(id: 'starlet', name: 'Starlet', shape: 'star', face: 'wink', accessory: 'none', colorArgb: 0xFFFF94D5, achievementId: 'perfect_25'),
    SkinDefinition(id: 'sleepy', name: 'Sleepyhead', shape: 'squircle', face: 'sleepy', accessory: 'moon', colorArgb: 0xFF8B9EFF, achievementId: 'streak_7'),
    SkinDefinition(id: 'captain', name: 'Captain Blob', shape: 'droplet', face: 'cyclops', accessory: 'helmet', colorArgb: 0xFF65D9D8, achievementId: 'combo_10'),
    SkinDefinition(id: 'aurora', name: 'Aurora', shape: 'round', face: 'smile', accessory: 'halo', colorArgb: 0xFF83F7DA, gemCost: 8),
    SkinDefinition(id: 'prism', name: 'Prism', shape: 'star', face: 'cyclops', accessory: 'visor', colorArgb: 0xFFD78BFF, gemCost: 12),
    SkinDefinition(id: 'nova', name: 'Nova', shape: 'droplet', face: 'wink', accessory: 'crown', colorArgb: 0xFFFF7C70, gemCost: 18),
    SkinDefinition(id: 'blackhole', name: 'Black Hole', shape: 'round', face: 'sleepy', accessory: 'ring', colorArgb: 0xFF8E85FF, gemCost: 25),
  ];

  static const List<TrailDefinition> trails = <TrailDefinition>[
    TrailDefinition(id: 'stardust', name: 'Stardust', colorArgb: 0xFF8DEBFF, coinCost: 0),
    TrailDefinition(id: 'bubblegum', name: 'Bubblegum', colorArgb: 0xFFFF81C5, coinCost: 180),
    TrailDefinition(id: 'lime', name: 'Lime fizz', colorArgb: 0xFF9DFF82, coinCost: 260),
    TrailDefinition(id: 'ember', name: 'Ember', colorArgb: 0xFFFF9C59, coinCost: 350),
    TrailDefinition(id: 'violet', name: 'Violet haze', colorArgb: 0xFFBA90FF, coinCost: 450),
    TrailDefinition(id: 'ice', name: 'Ice trail', colorArgb: 0xFF9FEFFF, coinCost: 600),
    TrailDefinition(id: 'sunbeam', name: 'Sunbeam', colorArgb: 0xFFFFE07A, coinCost: 780),
    TrailDefinition(id: 'ocean', name: 'Deep blue', colorArgb: 0xFF64A9FF, coinCost: 980),
    TrailDefinition(id: 'candy', name: 'Candy comet', colorArgb: 0xFFFF90B8, coinCost: 1200),
    TrailDefinition(id: 'aurora_trail', name: 'Aurora wave', colorArgb: 0xFF71F4CB, coinCost: 1500),
    TrailDefinition(id: 'prism_trail', name: 'Prismatic', colorArgb: 0xFFD38CFF, coinCost: 1800),
    TrailDefinition(id: 'golden', name: 'Golden hour', colorArgb: 0xFFFFC85C, coinCost: 0, achievementId: 'level_10'),
  ];

  static const List<ThemeDefinition> themes = <ThemeDefinition>[
    ThemeDefinition(id: 'moonlight', name: 'Moonlight', accentArgb: 0xFF8DEBFF, secondaryArgb: 0xFF91A7FF, backgroundArgb: 0xFF14172D),
    ThemeDefinition(id: 'saffron', name: 'Saffron', accentArgb: 0xFFFFD36E, secondaryArgb: 0xFFFF8D7E, backgroundArgb: 0xFF26192E, coinCost: 900),
    ThemeDefinition(id: 'verdant', name: 'Verdant', accentArgb: 0xFF72FFD2, secondaryArgb: 0xFF9DFF91, backgroundArgb: 0xFF102824, coinCost: 1200),
    ThemeDefinition(id: 'violet', name: 'Violet', accentArgb: 0xFFD6A6FF, secondaryArgb: 0xFF8D7DFF, backgroundArgb: 0xFF1E1533, coinCost: 1500),
    ThemeDefinition(id: 'tidal', name: 'Tidal', accentArgb: 0xFF69DAFF, secondaryArgb: 0xFF4E91FF, backgroundArgb: 0xFF101D38, coinCost: 1900),
    ThemeDefinition(id: 'solar', name: 'Solar', accentArgb: 0xFFFFAB77, secondaryArgb: 0xFFFF5E9A, backgroundArgb: 0xFF2B1325, coinCost: 2400),
  ];

  static SkinDefinition skinById(String id) => skins.firstWhere(
        (SkinDefinition item) => item.id == id,
        orElse: () => skins.first,
      );

  static TrailDefinition trailById(String id) => trails.firstWhere(
        (TrailDefinition item) => item.id == id,
        orElse: () => trails.first,
      );

  static ThemeDefinition themeById(String id) => themes.firstWhere(
        (ThemeDefinition item) => item.id == id,
        orElse: () => themes.first,
      );
}
