import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/logic/cat_crew.dart';
import '../game/logic/elemental_codex.dart';
import '../config/boss_config.dart';
import '../config/garden_config.dart';
import '../config/planet_config.dart';

/// Persistence service handling user progress, currency, settings, and heart regen.
class SaveService extends ChangeNotifier {
  static final SaveService I = SaveService._();
  SaveService._();

  static const String _prefKey = "cosmopop_v1";
  static const int kMaxHearts = 5;
  static const int kHeartRegenMs = 20 * 60 * 1000; // 20 minutes

  SharedPreferences? _prefs;
  Map<String, dynamic> _data = {};

  final Map<String, dynamic> _defaults = {
    'coins': 100,
    'gems': 0,
    'hearts': kMaxHearts,
    'lastHeartTime': DateTime.now().millisecondsSinceEpoch,
    'currentLevel': 1,
    'unlockedLevel': 1,
    'completedPlanets': <dynamic>[],
    'defeatedBosses': <dynamic>[],
    'garden': <String, dynamic>{},
    'highScore': 0,
    'highscores': <String, dynamic>{},
    'levelBestScores': <String, dynamic>{},
    'starsPerLevel': <String, dynamic>{},
    'cats': <dynamic>[0, ...CatRegistry.starterIds],
    'catLevels': <String, dynamic>{'0': 1, '1': 1, '2': 1, '4': 1, '6': 1},
    'activeCatId': 2,
    'discoveredReactions': <dynamic>[],
    'claimedCodexRewards': <dynamic>[],
    'eventProgress': 0,
    'eventState': <String, dynamic>{},
    'daily': <String, dynamic>{'lastClaim': '', 'streak': 0},
    'spin': <String, dynamic>{'lastFree': '', 'paidCount': 0},
    'powerups': <String, dynamic>{
      'bomb': 0,
      'rainbow': 0,
      'lightning': 0,
      'rocket': 0,
    },
    'selectedSkin': 'defaultMimo',
    'unlockedSkins': <dynamic>['defaultMimo'],
    'skins': <dynamic>['astronaut'],
    'skin': 'astronaut',
    'soundEnabled': true,
    'musicEnabled': true,
    'vibrateEnabled': true,
    'colorblindEnabled': false,
    'bubbleSize': 'M',
    'difficultyLevel': 1,
    'aimingMode': 'dotted',
    'sfxVolume': 1.0,
    'musicVolume': 0.8,
    'dailyRewardLastClaim': 0,
    'spinLastUsed': 0,
  };

  /// Loads saved state from SharedPreferences, merges defaults, and calculates offline hearts.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final jsonStr = _prefs?.getString(_prefKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _data = Map<String, dynamic>.from(decoded);
        } else {
          _resetToDefaults();
        }
      } else {
        _resetToDefaults();
      }
    } catch (e) {
      debugPrint("SaveService load error (resetting defaults): $e");
      _resetToDefaults();
    }

    _mergeDefaults();
    _normalizeCatProgress();
    _normalizeCodexProgress();
    _normalizeBossProgress();
    _normalizeGardenProgress();
    _normalizeSettings();
    _recalculateHearts();
    await _save();
    notifyListeners();
  }

  void _resetToDefaults() {
    _data = Map<String, dynamic>.from(_defaults);
    _data['lastHeartTime'] = DateTime.now().millisecondsSinceEpoch;
  }

  void _mergeDefaults() {
    _defaults.forEach((key, defaultValue) {
      if (!_data.containsKey(key) || _data[key] == null) {
        _data[key] = defaultValue;
      }
    });
  }

  void _normalizeSettings() {
    final size = _data['bubbleSize'];
    _data['bubbleSize'] = size is String && ['S', 'M', 'L'].contains(size)
        ? size
        : 'M';
    final difficulty = _data['difficultyLevel'];
    _data['difficultyLevel'] = difficulty is num
        ? difficulty.toInt().clamp(1, 4)
        : 1;
    final aiming = _data['aimingMode'];
    _data['aimingMode'] = aiming == 'laser' ? 'laser' : 'dotted';
    for (final key in ['sfxVolume', 'musicVolume']) {
      final volume = _data[key];
      _data[key] = volume is num ? volume.toDouble().clamp(0.0, 1.0) : 1.0;
    }
  }

  void _normalizeCatProgress() {
    final owned = <int>{
      if (_data['cats'] is List)
        for (final value in _data['cats'] as List)
          if (value is num &&
              value.toInt() >= 0 &&
              value.toInt() < CatRegistry.all.length)
            value.toInt(),
      0,
      ...CatRegistry.starterIds,
    };
    _data['cats'] = owned.toList()..sort();

    final levels = <String, dynamic>{};
    final rawLevels = _data['catLevels'];
    if (rawLevels is Map) {
      for (final id in owned) {
        final stored = rawLevels[id.toString()];
        final maxLevel = CatRegistry.getById(id).rarity.maxLevel;
        final level = stored is num ? stored.toInt() : 1;
        levels[id.toString()] = level.clamp(1, maxLevel);
      }
    }
    for (final id in owned) {
      levels.putIfAbsent(id.toString(), () => 1);
    }
    _data['catLevels'] = levels;

    final active = _data['activeCatId'];
    final activeId = active is num ? active.toInt() : -1;
    _data['activeCatId'] = owned.contains(activeId)
        ? activeId
        : CatRegistry.starterIds.first;
  }

  void _normalizeCodexProgress() {
    const aliases = {
      'burn': 'reaction_burn',
      'steam': 'reaction_steam',
      'mud': 'reaction_mud',
      'bloom': 'reaction_bloom',
      'double_chain': 'chain_double',
      'triple_chain': 'chain_triple',
    };
    final validIds = ElementalCodexRegistry.entries
        .map((entry) => entry.id)
        .toSet();
    Set<String> normalize(Object? raw) {
      if (raw is! List) return <String>{};
      return raw
          .map((value) => value.toString())
          .map((id) => aliases[id] ?? id)
          .where(validIds.contains)
          .toSet();
    }

    final discovered = normalize(_data['discoveredReactions']);
    _data['discoveredReactions'] = discovered.toList();
    _data['claimedCodexRewards'] = normalize(_data['claimedCodexRewards'])
        .intersection(discovered)
        .toList();
  }

  void _normalizeBossProgress() {
    final validIds = kBossEncounters.map((encounter) => encounter.id).toSet();
    final raw = _data['defeatedBosses'];
    _data['defeatedBosses'] = raw is List
        ? raw
              .map((value) => value.toString())
              .where(validIds.contains)
              .toSet()
              .toList()
        : <String>[];
  }

  void _normalizeGardenProgress() {
    final raw = _data['garden'];
    final source = raw is Map ? raw : const <Object?, Object?>{};
    final seeds = <String, int>{};
    final rawSeeds = source['seeds'];
    if (rawSeeds is Map) {
      for (final entry in rawSeeds.entries) {
        if (GardenCatalog.seed(entry.key.toString()) == null ||
            entry.value is! num) {
          continue;
        }
        seeds[entry.key.toString()] = (entry.value as num).toInt().clamp(
          0,
          9999,
        );
      }
    }

    final plants = <String, Map<String, Object>>{};
    final rawPlants = source['plants'];
    if (rawPlants is Map) {
      for (final entry in rawPlants.entries) {
        final slot = int.tryParse(entry.key.toString());
        final plant = entry.value;
        if (slot == null ||
            slot < 0 ||
            slot >= GardenCatalog.plotCount ||
            plant is! Map) {
          continue;
        }
        final seedId = plant['seedId']?.toString();
        if (GardenCatalog.seed(seedId) == null) continue;
        final rawGrowth = plant['growth'];
        final growth = rawGrowth is num ? rawGrowth.toInt() : 0;
        plants['$slot'] = {
          'seedId': seedId!,
          'growth': growth.clamp(0, GardenCatalog.growthWins),
        };
      }
    }

    final decorationIds = GardenCatalog.decorations
        .map((item) => item.id)
        .toSet();
    final ownedDecorations = <String>{
      if (source['decorations'] is List)
        for (final value in source['decorations'] as List)
          if (decorationIds.contains(value.toString())) value.toString(),
    };
    final placedDecorations = <String, String>{};
    final rawPlacements = source['placedDecorations'];
    if (rawPlacements is Map) {
      for (final entry in rawPlacements.entries) {
        final slot = int.tryParse(entry.key.toString());
        final id = entry.value.toString();
        if (slot != null &&
            slot >= 0 &&
            slot < GardenCatalog.decorationSlotCount &&
            ownedDecorations.contains(id) &&
            !placedDecorations.values.contains(id)) {
          placedDecorations['$slot'] = id;
        }
      }
    }

    final completedLevels = <int>{
      if (source['completedLevels'] is List)
        for (final value in source['completedLevels'] as List)
          if (value is num && value.toInt() >= 1 && value.toInt() <= 120)
            value.toInt(),
    };
    final totalRescues = source['totalRescues'] is num
        ? (source['totalRescues'] as num).toInt().clamp(0, 1 << 30)
        : 0;
    final validRewards = <String>{
      for (
        var level = GardenCatalog.seedRewardEveryLevels;
        level <= 120;
        level += GardenCatalog.seedRewardEveryLevels
      )
        'level_seed_$level',
      'rescues_5',
      'rescues_15',
    };
    final claimedRewards = <String>{
      if (source['claimedRewards'] is List)
        for (final value in source['claimedRewards'] as List)
          if (validRewards.contains(value.toString())) value.toString(),
    };

    _data['garden'] = <String, dynamic>{
      'seeds': seeds,
      'plants': plants,
      'decorations': ownedDecorations.toList(),
      'placedDecorations': placedDecorations,
      'completedLevels': completedLevels.toList()..sort(),
      'totalRescues': totalRescues,
      'claimedRewards': claimedRewards.toList(),
    };
  }

  Map<String, dynamic> get _gardenState {
    final value = _data['garden'];
    if (value is Map<String, dynamic>) return value;
    _normalizeGardenProgress();
    return _data['garden'] as Map<String, dynamic>;
  }

  Map<String, int> get gardenSeeds {
    final raw = _gardenState['seeds'];
    if (raw is! Map) return const {};
    return Map<String, int>.unmodifiable({
      for (final entry in raw.entries)
        entry.key.toString(): (entry.value as num).toInt(),
    });
  }

  Map<int, GardenPlant> get gardenPlants {
    final raw = _gardenState['plants'];
    if (raw is! Map) return const {};
    return Map<int, GardenPlant>.unmodifiable({
      for (final entry in raw.entries)
        int.parse(entry.key.toString()): GardenPlant(
          seedId: (entry.value as Map)['seedId'].toString(),
          growth: ((entry.value as Map)['growth'] as num).toInt(),
        ),
    });
  }

  Set<String> get gardenDecorations =>
      ((_gardenState['decorations'] as List?) ?? const [])
          .map((value) => value.toString())
          .toSet();

  Map<int, String> get placedGardenDecorations {
    final raw = _gardenState['placedDecorations'];
    if (raw is! Map) return const {};
    return Map<int, String>.unmodifiable({
      for (final entry in raw.entries)
        int.parse(entry.key.toString()): entry.value.toString(),
    });
  }

  Set<int> get gardenCompletedLevels =>
      ((_gardenState['completedLevels'] as List?) ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toSet();

  int get gardenTotalRescues =>
      (_gardenState['totalRescues'] as num?)?.toInt() ?? 0;

  int get gardenCompletedLevelCount => gardenCompletedLevels.length;

  bool buyGardenSeed(String seedId) {
    final seed = GardenCatalog.seed(seedId);
    if (seed == null || coins < seed.price) return false;
    _data['coins'] = coins - seed.price;
    final seeds = Map<String, dynamic>.from(_gardenState['seeds'] as Map);
    seeds[seedId] = ((seeds[seedId] as num?)?.toInt() ?? 0) + 1;
    _gardenState['seeds'] = seeds;
    _save();
    notifyListeners();
    return true;
  }

  bool plantGardenSeed(String seedId, int slot) {
    if (GardenCatalog.seed(seedId) == null ||
        slot < 0 ||
        slot >= GardenCatalog.plotCount) {
      return false;
    }
    final plants = Map<String, dynamic>.from(_gardenState['plants'] as Map);
    final seeds = Map<String, dynamic>.from(_gardenState['seeds'] as Map);
    final count = (seeds[seedId] as num?)?.toInt() ?? 0;
    if (plants.containsKey('$slot') || count <= 0) return false;
    seeds[seedId] = count - 1;
    plants['$slot'] = GardenPlant(seedId: seedId, growth: 0).toJson();
    _gardenState
      ..['seeds'] = seeds
      ..['plants'] = plants;
    _save();
    notifyListeners();
    return true;
  }

  bool buyGardenDecoration(String decorationId) {
    final decoration = GardenCatalog.decoration(decorationId);
    if (decoration == null ||
        decoration.price == null ||
        gardenDecorations.contains(decorationId) ||
        coins < decoration.price!) {
      return false;
    }
    _data['coins'] = coins - decoration.price!;
    _gardenState['decorations'] = [...gardenDecorations, decorationId];
    _save();
    notifyListeners();
    return true;
  }

  bool placeGardenDecoration(String decorationId, int slot) {
    if (!gardenDecorations.contains(decorationId) ||
        slot < 0 ||
        slot >= GardenCatalog.decorationSlotCount) {
      return false;
    }
    final placements = Map<String, dynamic>.from(
      _gardenState['placedDecorations'] as Map,
    );
    for (final key in placements.keys.toList()) {
      if (key != '$slot' && placements[key] == decorationId) {
        placements.remove(key);
      }
    }
    placements['$slot'] = decorationId;
    _gardenState['placedDecorations'] = placements;
    _save();
    notifyListeners();
    return true;
  }

  bool removeGardenDecoration(int slot) {
    if (slot < 0 || slot >= GardenCatalog.decorationSlotCount) return false;
    final placements = Map<String, dynamic>.from(
      _gardenState['placedDecorations'] as Map,
    );
    if (placements.remove('$slot') == null) return false;
    _gardenState['placedDecorations'] = placements;
    _save();
    notifyListeners();
    return true;
  }

  bool gardenDecorationIsPlaced(String decorationId) =>
      placedGardenDecorations.containsValue(decorationId);

  Set<String> get _gardenClaimedRewards =>
      ((_gardenState['claimedRewards'] as List?) ?? const [])
          .map((value) => value.toString())
          .toSet();

  GardenProgressUpdate recordGardenLevelCompletion(
    int level, {
    required int rescued,
  }) {
    final completedLevels = gardenCompletedLevels;
    if (level < 1 ||
        level > 120 ||
        rescued < 0 ||
        completedLevels.contains(level)) {
      return GardenProgressUpdate(
        wasNewLevel: false,
        completedLevels: completedLevels.length,
        totalRescues: gardenTotalRescues,
      );
    }

    completedLevels.add(level);
    final state = _gardenState;
    state['completedLevels'] = completedLevels.toList()..sort();
    state['totalRescues'] = gardenTotalRescues + rescued;
    final plants = Map<String, dynamic>.from(state['plants'] as Map);
    for (final entry in plants.entries.toList()) {
      final plant = entry.value as Map;
      final growth = (plant['growth'] as num).toInt();
      if (growth < GardenCatalog.growthWins) {
        plants[entry.key] = {
          'seedId': plant['seedId'].toString(),
          'growth': growth + 1,
        };
      }
    }
    state['plants'] = plants;

    final claimed = <String>{..._gardenClaimedRewards};
    final unlockedDecorations = <String>{...gardenDecorations};
    final seeds = Map<String, dynamic>.from(state['seeds'] as Map);
    final rewards = <String>[];
    final levelMilestone =
        completedLevels.length -
        completedLevels.length % GardenCatalog.seedRewardEveryLevels;
    final levelRewardId = 'level_seed_${completedLevels.length}';
    if (levelMilestone > 0 && !claimed.contains(levelRewardId)) {
      claimed.add(levelRewardId);
      seeds['moon_daisy'] = ((seeds['moon_daisy'] as num?)?.toInt() ?? 0) + 1;
      rewards.add('MOON DAISY SEED');
    }

    final rescueMilestones = <(int, String, String)>[
      (5, 'rescues_5', 'rescue_lantern'),
      (15, 'rescues_15', 'nebula_arch'),
    ];
    final totalRescues = (state['totalRescues'] as num).toInt();
    for (final (threshold, rewardId, decorationId) in rescueMilestones) {
      if (totalRescues >= threshold &&
          !claimed.contains(rewardId) &&
          !unlockedDecorations.contains(decorationId)) {
        claimed.add(rewardId);
        unlockedDecorations.add(decorationId);
        rewards.add(GardenCatalog.decoration(decorationId)!.name);
      }
    }
    state
      ..['seeds'] = seeds
      ..['decorations'] = unlockedDecorations.toList()
      ..['claimedRewards'] = claimed.toList();
    _save();
    notifyListeners();
    return GardenProgressUpdate(
      wasNewLevel: true,
      completedLevels: completedLevels.length,
      totalRescues: totalRescues,
      rewards: List.unmodifiable(rewards),
    );
  }

  Future<void> _save() async {
    try {
      if (_prefs != null) {
        final jsonStr = jsonEncode(_data);
        await _prefs!.setString(_prefKey, jsonStr);
      }
    } catch (e) {
      debugPrint("SaveService save error: $e");
    }
  }

  // ============================================================================
  // HEARTS & REGENERATION
  // ============================================================================

  void _recalculateHearts() {
    final int currentHearts = (_data['hearts'] as num?)?.toInt() ?? kMaxHearts;
    if (currentHearts >= kMaxHearts) {
      _data['hearts'] = kMaxHearts;
      return;
    }

    final int lastTime =
        (_data['lastHeartTime'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsed = now - lastTime;

    if (elapsed >= kHeartRegenMs) {
      final int gained = elapsed ~/ kHeartRegenMs;
      final int newHearts = (currentHearts + gained).clamp(0, kMaxHearts);
      _data['hearts'] = newHearts;

      if (newHearts >= kMaxHearts) {
        _data['lastHeartTime'] = now;
      } else {
        _data['lastHeartTime'] = lastTime + (gained * kHeartRegenMs);
      }
    }
  }

  /// Duration remaining until the next heart regenerates.
  Duration get nextHeartIn {
    _recalculateHearts();
    final int currentHearts = (_data['hearts'] as num?)?.toInt() ?? kMaxHearts;
    if (currentHearts >= kMaxHearts) {
      return Duration.zero;
    }

    final int lastTime =
        (_data['lastHeartTime'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsed = now - lastTime;
    final int remainingMs = kHeartRegenMs - (elapsed % kHeartRegenMs);

    return Duration(milliseconds: remainingMs.clamp(0, kHeartRegenMs));
  }

  int get hearts {
    _recalculateHearts();
    return (_data['hearts'] as num?)?.toInt() ?? kMaxHearts;
  }

  bool useHeart() {
    _recalculateHearts();
    final int h = hearts;
    if (h <= 0) return false;

    if (h == kMaxHearts) {
      _data['lastHeartTime'] = DateTime.now().millisecondsSinceEpoch;
    }
    _data['hearts'] = h - 1;
    _save();
    notifyListeners();
    return true;
  }

  void addHearts(int amount) {
    _recalculateHearts();
    final int h = hearts;
    _data['hearts'] = (h + amount).clamp(0, kMaxHearts);
    if (_data['hearts'] == kMaxHearts) {
      _data['lastHeartTime'] = DateTime.now().millisecondsSinceEpoch;
    }
    _save();
    notifyListeners();
  }

  // ============================================================================
  // COINS & CURRENCY
  // ============================================================================

  int get coins => (_data['coins'] as num?)?.toInt() ?? 100;

  void addCoins(int amount) {
    if (amount <= 0) return;
    _data['coins'] = coins + amount;
    _save();
    notifyListeners();
  }

  int get gems => (_data['gems'] as num?)?.toInt() ?? 0;

  void addGems(int amount) {
    if (amount <= 0) return;
    _data['gems'] = gems + amount;
    _save();
    notifyListeners();
  }

  bool spendGems(int amount) {
    if (amount < 0 || gems < amount) return false;
    _data['gems'] = gems - amount;
    _save();
    notifyListeners();
    return true;
  }

  bool deductCoins(int amount) {
    if (amount <= 0 || coins < amount) return false;
    _data['coins'] = coins - amount;
    _save();
    notifyListeners();
    return true;
  }

  // ============================================================================
  // LEVELS & PROGRESSION
  // ============================================================================

  int get currentLevel => (_data['currentLevel'] as num?)?.toInt() ?? 1;

  set currentLevel(int lvl) {
    _data['currentLevel'] = lvl;
    _save();
    notifyListeners();
  }

  int get unlockedLevel => (_data['unlockedLevel'] as num?)?.toInt() ?? 1;

  int get totalStarsEarned {
    var total = 0;
    for (var level = 1; level <= 120; level++) {
      total += getStarsForLevel(level).clamp(0, 3);
    }
    return total;
  }

  void unlockLevel(int lvl) {
    if (lvl > unlockedLevel) {
      _data['unlockedLevel'] = lvl;
      _save();
      notifyListeners();
    }
  }

  bool isPlanetUnlocked(PlanetId id) {
    final planet = PlanetRegistry.byId(id.name);
    return planet != null && unlockedLevel >= planet.firstLevel;
  }

  Set<String> get completedPlanets {
    final raw = _data['completedPlanets'];
    if (raw is! List) return <String>{};
    final valid = PlanetRegistry.worlds.map((planet) => planet.id.name).toSet();
    return raw.map((value) => value.toString()).where(valid.contains).toSet();
  }

  bool isPlanetCompleted(PlanetId id) => completedPlanets.contains(id.name);

  int planetLevelProgress(PlanetId id) {
    final planet = PlanetRegistry.byId(id.name);
    if (planet == null || !isPlanetUnlocked(id)) return 0;
    if (isPlanetCompleted(id)) return planet.levelCount;
    return (unlockedLevel - planet.firstLevel).clamp(0, planet.levelCount);
  }

  bool completePlanet(PlanetId id, {required int completedLevel}) {
    final planet = PlanetRegistry.byId(id.name);
    if (planet == null ||
        completedLevel != planet.lastLevel ||
        unlockedLevel < planet.lastLevel ||
        !isPlanetUnlocked(id) ||
        isPlanetCompleted(id)) {
      return false;
    }
    _data['completedPlanets'] = [...completedPlanets, id.name];
    addCoins(planet.completionRewardCoins);
    _save();
    notifyListeners();
    return true;
  }

  Set<String> get defeatedBosses {
    final raw = _data['defeatedBosses'];
    if (raw is! List) return <String>{};
    final validIds = kBossEncounters.map((encounter) => encounter.id).toSet();
    return raw
        .map((value) => value.toString())
        .where(validIds.contains)
        .toSet();
  }

  bool isBossDefeated(String encounterId) =>
      defeatedBosses.contains(encounterId);

  bool recordBossVictory(String encounterId) {
    if (!kBossEncounters.any((encounter) => encounter.id == encounterId) ||
        isBossDefeated(encounterId)) {
      return false;
    }
    _data['defeatedBosses'] = [...defeatedBosses, encounterId];
    _save();
    notifyListeners();
    return true;
  }

  int get highScore => (_data['highScore'] as num?)?.toInt() ?? 0;

  void updateHighScore(int score) {
    if (score > highScore) {
      _data['highScore'] = score;
      _save();
      notifyListeners();
    }
  }

  Map<String, int> get highscores {
    final stored = _data['highscores'];
    if (stored is! Map) return const {};
    return stored.map(
      (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
    );
  }

  bool updateModeHighScore(String mode, int score) {
    final scores = highscores;
    if (score <= (scores[mode] ?? 0)) return false;
    scores[mode] = score;
    _data['highscores'] = scores;
    _save();
    notifyListeners();
    return true;
  }

  int getLevelBestScore(int level) {
    final scores = _data['levelBestScores'];
    if (scores is! Map) return 0;
    return (scores[level.toString()] as num?)?.toInt() ?? 0;
  }

  bool updateLevelBestScore(int level, int score) {
    final scores = <String, int>{
      if (_data['levelBestScores'] is Map)
        for (final entry in (_data['levelBestScores'] as Map).entries)
          entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    };
    if (score <= (scores[level.toString()] ?? 0)) return false;
    scores[level.toString()] = score;
    _data['levelBestScores'] = scores;
    _save();
    notifyListeners();
    return true;
  }

  List<int> get cats {
    final stored = _data['cats'];
    if (stored is! List) return const [];
    return stored
        .whereType<num>()
        .map((id) => id.toInt())
        .where((id) => id >= 0 && id < CatRegistry.all.length)
        .toSet()
        .toList()
      ..sort();
  }

  List<int> addCats(int amount, {Random? random}) {
    if (amount <= 0) return const [];
    final owned = cats.toSet();
    final available = List<int>.generate(24, (id) => id)
      ..removeWhere(owned.contains);
    available.shuffle(random);
    final unlocked = available.take(amount).toList(growable: false);
    if (unlocked.isNotEmpty) {
      _data['cats'] = [...owned, ...unlocked]..sort();
      _save();
      notifyListeners();
    }
    return unlocked;
  }

  // ============================================================================
  // CAT CREW & PROGRESSION
  // ============================================================================

  int get activeCatId => (_data['activeCatId'] as num?)?.toInt() ?? 0;

  set activeCatId(int catId) {
    if (catId >= 0 && catId < CatRegistry.all.length && cats.contains(catId)) {
      _data['activeCatId'] = catId;
      _save();
      notifyListeners();
    }
  }

  int getCatLevel(int catId) {
    final map = _data['catLevels'];
    if (map is Map) {
      final raw = map[catId.toString()];
      return raw is num
          ? raw.toInt().clamp(1, CatRegistry.getById(catId).rarity.maxLevel)
          : 1;
    }
    return 1;
  }

  CatProgress catProgress(int catId) {
    final cat = CatRegistry.getById(catId);
    return CatProgress(
      cat: cat,
      level: getCatLevel(cat.id),
      isOwned: cats.contains(cat.id),
    );
  }

  bool upgradeCat(int catId, [int? requestedCost]) {
    if (catId < 0 || catId >= CatRegistry.all.length || !cats.contains(catId)) {
      return false;
    }
    final cat = CatRegistry.getById(catId);
    final currentLevel = getCatLevel(catId);
    if (currentLevel >= cat.rarity.maxLevel) return false;
    final cost = cat.upgradeCost(currentLevel);
    if (cost <= 0 || (requestedCost != null && requestedCost != cost)) {
      return false;
    }
    if (!deductCoins(cost)) return false;

    if (!_data.containsKey('catLevels') || _data['catLevels'] is! Map) {
      _data['catLevels'] = <String, dynamic>{};
    }
    final Map map = _data['catLevels'] as Map;
    map[catId.toString()] = currentLevel + 1;
    _save();
    notifyListeners();
    return true;
  }

  // ============================================================================
  // ELEMENTAL CODEX
  // ============================================================================

  Set<String> get discoveredReactions {
    final raw = _data['discoveredReactions'];
    if (raw is! List) return {};
    final valid = ElementalCodexRegistry.entries
        .map((entry) => entry.id)
        .toSet();
    return raw.map((e) => e.toString()).where(valid.contains).toSet();
  }

  bool discoverReaction(String reactionId) {
    if (!ElementalCodexRegistry.entries.any(
      (entry) => entry.id == reactionId,
    )) {
      return false;
    }
    final set = discoveredReactions;
    if (set.contains(reactionId)) return false;
    set.add(reactionId);
    _data['discoveredReactions'] = set.toList();
    _save();
    notifyListeners();
    return true;
  }

  Set<String> get claimedCodexRewards {
    final raw = _data['claimedCodexRewards'];
    if (raw is! List) return {};
    return raw
        .map((e) => e.toString())
        .where(discoveredReactions.contains)
        .toSet();
  }

  bool claimCodexReward(String entryId) {
    CodexEntry? entry;
    for (final candidate in ElementalCodexRegistry.entries) {
      if (candidate.id == entryId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) return false;
    final claimed = claimedCodexRewards;
    if (!discoveredReactions.contains(entryId) || claimed.contains(entryId)) {
      return false;
    }
    claimed.add(entryId);
    _data['claimedCodexRewards'] = claimed.toList();
    _data['coins'] = coins + entry.rewardCoins;
    _data['gems'] = gems + entry.rewardGems;
    _save();
    notifyListeners();
    return true;
  }

  int get eventProgress {
    final week = _dateKey(_weekStart(DateTime.now()));
    if (_data['eventProgressWeek'] != week) return 0;
    return (_data['eventProgress'] as num?)?.toInt() ?? 0;
  }

  void addEventProgress(int amount) {
    if (amount <= 0) return;
    final progress = eventProgress;
    _data['eventProgressWeek'] = _dateKey(_weekStart(DateTime.now()));
    _data['eventProgress'] = progress + amount;
    _save();
    notifyListeners();
  }

  Set<int> get claimedCatalogMilestones {
    final raw = _data['catalogRewards'];
    if (raw is! List) return {};
    return raw.whereType<num>().map((value) => value.toInt()).toSet();
  }

  bool claimCatalogMilestone(int milestone) {
    if (![5, 10, 20].contains(milestone) ||
        cats.length < milestone ||
        claimedCatalogMilestones.contains(milestone)) {
      return false;
    }
    final reward = milestone == 5
        ? 100
        : milestone == 10
        ? 250
        : 500;
    addCoins(reward);
    _data['catalogRewards'] = [...claimedCatalogMilestones, milestone];
    _save();
    notifyListeners();
    return true;
  }

  int getStarsForLevel(int level) {
    final starsMap = _data['starsPerLevel'];
    if (starsMap is Map) {
      return (starsMap[level.toString()] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  void setStarsForLevel(int level, int stars) {
    if (!_data.containsKey('starsPerLevel') || _data['starsPerLevel'] is! Map) {
      _data['starsPerLevel'] = <String, dynamic>{};
    }
    final Map map = _data['starsPerLevel'] as Map;
    final int current = (map[level.toString()] as num?)?.toInt() ?? 0;
    if (stars > current) {
      map[level.toString()] = stars;
      _save();
      notifyListeners();
    }
  }

  Map<String, int> get powerups {
    final stored = _data['powerups'];
    if (stored is Map) {
      return {
        'bomb': (stored['bomb'] as num?)?.toInt() ?? 0,
        'rainbow': (stored['rainbow'] as num?)?.toInt() ?? 0,
        'lightning': (stored['lightning'] as num?)?.toInt() ?? 0,
        'rocket': (stored['rocket'] as num?)?.toInt() ?? 0,
      };
    }
    return const {'bomb': 0, 'rainbow': 0, 'lightning': 0, 'rocket': 0};
  }

  bool usePowerup(String powerup) {
    final counts = powerups;
    final count = counts[powerup];
    if (count == null || count <= 0) return false;
    counts[powerup] = count - 1;
    _data['powerups'] = counts;
    _save();
    notifyListeners();
    return true;
  }

  void addPowerups(String powerup, int amount) {
    if (amount <= 0 || !powerups.containsKey(powerup)) return;
    final counts = powerups;
    counts[powerup] = counts[powerup]! + amount;
    _data['powerups'] = counts;
    _save();
    notifyListeners();
  }

  bool purchasePowerup(String powerup, int price) {
    final counts = powerups;
    if (price <= 0 || !counts.containsKey(powerup) || coins < price) {
      return false;
    }
    _data['coins'] = coins - price;
    counts[powerup] = counts[powerup]! + 1;
    _data['powerups'] = counts;
    _save();
    notifyListeners();
    return true;
  }

  // ============================================================================
  // SKINS & COSMETICS
  // ============================================================================

  String get selectedSkin =>
      (_data['selectedSkin'] as String?) ?? 'defaultMimo';

  set selectedSkin(String skinId) {
    _data['selectedSkin'] = skinId;
    _data['skin'] = switch (skinId) {
      'spaceMimo' => 'pirate',
      'neonMimo' => 'wizard',
      'goldenMimo' => 'ninja',
      _ => 'astronaut',
    };
    _save();
    notifyListeners();
  }

  List<String> get unlockedSkins {
    final list = _data['unlockedSkins'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return ['defaultMimo'];
  }

  List<String> get skins {
    final stored = _data['skins'];
    if (stored is List) return stored.map((e) => e.toString()).toList();
    final legacy = unlockedSkins;
    return legacy
        .map(
          (id) => switch (id) {
            'defaultMimo' => 'astronaut',
            'spaceMimo' => 'pirate',
            'neonMimo' => 'wizard',
            'goldenMimo' => 'ninja',
            _ => id,
          },
        )
        .toList();
  }

  String get skin =>
      (_data['skin'] as String?) ??
      switch (selectedSkin) {
        'spaceMimo' => 'pirate',
        'neonMimo' => 'wizard',
        'goldenMimo' => 'ninja',
        _ => 'astronaut',
      };

  void equipSkin(String id) {
    if (!skins.contains(id)) return;
    _data['skin'] = id;
    _data['selectedSkin'] = switch (id) {
      'pirate' => 'spaceMimo',
      'wizard' => 'neonMimo',
      'ninja' => 'goldenMimo',
      _ => 'defaultMimo',
    };
    _save();
    notifyListeners();
  }

  bool buySkin(String id, int price) {
    if (skins.contains(id) || !deductCoins(price)) return false;
    _data['skins'] = [...skins, id];
    _data['unlockedSkins'] = [
      ...unlockedSkins,
      switch (id) {
        'pirate' => 'spaceMimo',
        'wizard' => 'neonMimo',
        'ninja' => 'goldenMimo',
        _ => 'defaultMimo',
      },
    ];
    _save();
    notifyListeners();
    return true;
  }

  void unlockSkin(String skinId) {
    final skins = unlockedSkins;
    if (!skins.contains(skinId)) {
      skins.add(skinId);
      _data['unlockedSkins'] = skins;
      _save();
      notifyListeners();
    }
  }

  // ============================================================================
  // AUDIO & SETTINGS
  // ============================================================================

  bool get soundEnabled => (_data['soundEnabled'] as bool?) ?? true;
  set soundEnabled(bool value) {
    _data['soundEnabled'] = value;
    _save();
    notifyListeners();
  }

  bool get musicEnabled => (_data['musicEnabled'] as bool?) ?? true;
  set musicEnabled(bool value) {
    _data['musicEnabled'] = value;
    _save();
    notifyListeners();
  }

  bool get vibrateEnabled => (_data['vibrateEnabled'] as bool?) ?? true;
  set vibrateEnabled(bool value) {
    _data['vibrateEnabled'] = value;
    _save();
    notifyListeners();
  }

  bool get colorblindEnabled => (_data['colorblindEnabled'] as bool?) ?? false;
  set colorblindEnabled(bool value) {
    _data['colorblindEnabled'] = value;
    _save();
    notifyListeners();
  }

  String get bubbleSize => (_data['bubbleSize'] as String?) ?? 'M';
  set bubbleSize(String size) {
    _data['bubbleSize'] = ['S', 'M', 'L'].contains(size) ? size : 'M';
    _save();
    notifyListeners();
  }

  int get difficultyLevel => (_data['difficultyLevel'] as num?)?.toInt() ?? 1;
  set difficultyLevel(int level) {
    _data['difficultyLevel'] = level.clamp(1, 4);
    _save();
    notifyListeners();
  }

  String get aimingMode => (_data['aimingMode'] as String?) ?? 'dotted';
  set aimingMode(String mode) {
    _data['aimingMode'] = mode;
    _save();
    notifyListeners();
  }

  double get sfxVolume => (_data['sfxVolume'] as num?)?.toDouble() ?? 1.0;
  set sfxVolume(double vol) {
    _data['sfxVolume'] = vol.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  double get musicVolume => (_data['musicVolume'] as num?)?.toDouble() ?? 0.8;
  set musicVolume(double vol) {
    _data['musicVolume'] = vol.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  // ============================================================================
  // DAILY REWARDS & SPINS
  // ============================================================================

  int get dailyRewardLastClaim =>
      (_data['dailyRewardLastClaim'] as num?)?.toInt() ?? 0;

  String _dateKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  Map<String, dynamic> get daily {
    final stored = _data['daily'];
    return stored is Map
        ? Map<String, dynamic>.from(stored)
        : <String, dynamic>{'lastClaim': '', 'streak': 0};
  }

  bool get dailyClaimable => daily['lastClaim'] != _dateKey();

  int get dailyStreak {
    final state = daily;
    final lastClaim = _parseDate(state['lastClaim']?.toString() ?? '');
    if (lastClaim == null) return 0;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_dateKey(lastClaim) == _dateKey()) {
      return (state['streak'] as num?)?.toInt() ?? 0;
    }
    return _dateKey(lastClaim) == _dateKey(yesterday)
        ? (state['streak'] as num?)?.toInt() ?? 0
        : 0;
  }

  Map<String, int> dailyReward(int day) {
    const rewards = [
      {'coins': 50},
      {'bomb': 1},
      {'coins': 100},
      {'rainbow': 1},
      {'gems': 3},
      {'rocket': 1},
      {'coins': 250, 'gems': 10},
    ];
    return rewards[(day - 1).clamp(0, 6)];
  }

  bool claimDailyReward() {
    if (!dailyClaimable) return false;
    final day = dailyStreak % 7 + 1;
    final rewards = dailyReward(day);
    if (rewards.containsKey('coins')) addCoins(rewards['coins']!);
    if (rewards.containsKey('gems')) addGems(rewards['gems']!);
    for (final id in ['bomb', 'rainbow', 'lightning', 'rocket']) {
      final amount = rewards[id] ?? 0;
      if (amount > 0) addPowerups(id, amount);
    }
    _data['daily'] = {'lastClaim': _dateKey(), 'streak': day};
    _data['dailyRewardLastClaim'] = DateTime.now().millisecondsSinceEpoch;
    _save();
    notifyListeners();
    return true;
  }

  bool get hasFreeSpin => _spinState['lastFree'] != _dateKey();
  Map<String, dynamic> get _spinState {
    final stored = _data['spin'];
    return stored is Map
        ? Map<String, dynamic>.from(stored)
        : <String, dynamic>{'lastFree': '', 'paidCount': 0};
  }

  int get paidSpinsToday => _spinState['paidDate'] == _dateKey()
      ? (_spinState['paidCount'] as num?)?.toInt() ?? 0
      : 0;

  bool claimSpin({required bool paid}) {
    final state = _spinState;
    if (paid) {
      if (paidSpinsToday >= 5 || !deductCoins(150)) return false;
      state['paidDate'] = _dateKey();
      state['paidCount'] = paidSpinsToday + 1;
    } else {
      if (!hasFreeSpin) return false;
      state['lastFree'] = _dateKey();
    }
    _data['spin'] = state;
    _data['spinLastUsed'] = DateTime.now().millisecondsSinceEpoch;
    _save();
    notifyListeners();
    return true;
  }

  bool get eventActive {
    return true;
  }

  Map<String, dynamic> get _eventState {
    final stored = _data['eventState'];
    return stored is Map ? Map<String, dynamic>.from(stored) : {};
  }

  Set<int> get claimedEventTiers {
    final state = _eventState;
    if (state['week'] != _dateKey(_weekStart(DateTime.now()))) return {};
    final raw = state['claimed'];
    if (raw is! List) return {};
    return raw.whereType<num>().map((item) => item.toInt()).toSet();
  }

  DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  bool claimEventTier(int tier) {
    const thresholds = {1: 50, 2: 100, 3: 200, 4: 200};
    if (!eventActive ||
        !thresholds.containsKey(tier) ||
        eventProgress < thresholds[tier]! ||
        claimedEventTiers.contains(tier)) {
      return false;
    }
    if (tier == 4) {
      addGems(25);
    } else {
      addCoins(
        tier == 1
            ? 100
            : tier == 2
            ? 250
            : 500,
      );
    }
    _data['eventState'] = {
      'week': _dateKey(_weekStart(DateTime.now())),
      'claimed': [...claimedEventTiers, tier],
    };
    _save();
    notifyListeners();
    return true;
  }

  int get spinLastUsed => (_data['spinLastUsed'] as num?)?.toInt() ?? 0;

  void recordSpinUsed() {
    final state = _spinState..['lastFree'] = _dateKey();
    _data['spin'] = state;
    _data['spinLastUsed'] = DateTime.now().millisecondsSinceEpoch;
    _save();
    notifyListeners();
  }
}
