import 'dart:convert';
import 'dart:math';

import 'package:bubble_it/core/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'weekly event progress and claimed tiers reset at the week boundary',
    () async {
      SharedPreferences.setMockInitialValues({
        'cosmopop_v1': jsonEncode({
          'eventProgress': 190,
          'eventProgressWeek': '2000-01-03',
          'eventState': {
            'week': '2000-01-03',
            'claimed': [1],
          },
        }),
      });

      await SaveService.I.load();
      expect(SaveService.I.eventProgress, 0);
      expect(SaveService.I.claimedEventTiers, isEmpty);

      SaveService.I.addEventProgress(50);
      expect(SaveService.I.eventProgress, 50);
      expect(SaveService.I.claimEventTier(1), isTrue);
      expect(SaveService.I.claimedEventTiers, contains(1));
      expect(SaveService.I.claimEventTier(1), isFalse);
    },
  );

  test('daily streak rewards and catalog milestones grant once', () async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.I.load();

    expect(SaveService.I.dailyClaimable, isTrue);
    expect(SaveService.I.claimDailyReward(), isTrue);
    expect(SaveService.I.dailyStreak, 1);
    expect(SaveService.I.dailyClaimable, isFalse);
    expect(SaveService.I.claimDailyReward(), isFalse);

    SaveService.I.addCats(5, random: Random(4));
    final before = SaveService.I.coins;
    expect(SaveService.I.claimCatalogMilestone(5), isTrue);
    expect(SaveService.I.coins, before + 100);
    expect(SaveService.I.claimCatalogMilestone(5), isFalse);
  });

  test('settings normalize safely and persist valid values', () async {
    SharedPreferences.setMockInitialValues({
      'cosmopop_v1': jsonEncode({
        'bubbleSize': 'XXL',
        'difficultyLevel': 99,
        'aimingMode': 'invalid',
        'sfxVolume': 3.0,
        'musicVolume': -1,
      }),
    });
    await SaveService.I.load();

    expect(SaveService.I.bubbleSize, 'M');
    expect(SaveService.I.difficultyLevel, 4);
    expect(SaveService.I.aimingMode, 'dotted');
    expect(SaveService.I.sfxVolume, 1.0);
    expect(SaveService.I.musicVolume, 0.0);

    SaveService.I.bubbleSize = 'L';
    SaveService.I.difficultyLevel = 2;
    SaveService.I.aimingMode = 'laser';
    SaveService.I.sfxVolume = 0.35;
    SaveService.I.musicVolume = 0.65;
    await SaveService.I.load();

    expect(SaveService.I.bubbleSize, 'L');
    expect(SaveService.I.difficultyLevel, 2);
    expect(SaveService.I.aimingMode, 'laser');
    expect(SaveService.I.sfxVolume, 0.35);
    expect(SaveService.I.musicVolume, 0.65);
  });
}
