import 'package:bubble_it/config/garden_config.dart';
import 'package:bubble_it/core/save_service.dart';
import 'package:bubble_it/screens/garden_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.I.load();
  });

  test('seed purchases validate balance and planting consumes inventory', () {
    final initialCoins = SaveService.I.coins;
    expect(SaveService.I.buyGardenSeed('not-a-seed'), isFalse);
    expect(SaveService.I.buyGardenSeed('moon_daisy'), isTrue);
    expect(SaveService.I.coins, initialCoins - 60);
    expect(SaveService.I.gardenSeeds['moon_daisy'], 1);

    expect(SaveService.I.plantGardenSeed('moon_daisy', -1), isFalse);
    expect(SaveService.I.plantGardenSeed('moon_daisy', 4), isFalse);
    expect(SaveService.I.plantGardenSeed('moon_daisy', 0), isTrue);
    expect(SaveService.I.gardenSeeds['moon_daisy'], 0);
    expect(SaveService.I.gardenPlants[0]?.stage, GardenGrowthStage.seed);
    expect(SaveService.I.plantGardenSeed('moon_daisy', 0), isFalse);
    expect(SaveService.I.plantGardenSeed('moon_daisy', 1), isFalse);
  });

  test('coin purchases cannot overspend and decorations can be moved', () {
    final balance = SaveService.I.coins;
    expect(SaveService.I.buyGardenDecoration('comet_fountain'), isFalse);
    expect(SaveService.I.coins, balance);
    expect(SaveService.I.buyGardenDecoration('not-a-decoration'), isFalse);

    SaveService.I.addCoins(200);
    expect(SaveService.I.buyGardenDecoration('star_lantern'), isTrue);
    final afterPurchase = SaveService.I.coins;
    expect(SaveService.I.buyGardenDecoration('star_lantern'), isFalse);
    expect(SaveService.I.coins, afterPurchase);
    expect(SaveService.I.placeGardenDecoration('star_lantern', 0), isTrue);
    expect(SaveService.I.placeGardenDecoration('star_lantern', 2), isTrue);
    expect(SaveService.I.placedGardenDecorations, {2: 'star_lantern'});
    expect(SaveService.I.placeGardenDecoration('moon_gate', 1), isFalse);
    expect(SaveService.I.removeGardenDecoration(2), isTrue);
    expect(SaveService.I.removeGardenDecoration(2), isFalse);
  });

  test(
    'unique level clears grow flowers and grant one-time seed and rescue gifts',
    () {
      SaveService.I.buyGardenSeed('moon_daisy');
      SaveService.I.plantGardenSeed('moon_daisy', 0);

      final first = SaveService.I.recordGardenLevelCompletion(1, rescued: 2);
      expect(first.wasNewLevel, isTrue);
      expect(SaveService.I.gardenPlants[0]?.stage, GardenGrowthStage.sprout);
      final replay = SaveService.I.recordGardenLevelCompletion(1, rescued: 99);
      expect(replay.wasNewLevel, isFalse);
      expect(SaveService.I.gardenTotalRescues, 2);
      expect(SaveService.I.gardenPlants[0]?.stage, GardenGrowthStage.sprout);

      SaveService.I.recordGardenLevelCompletion(2, rescued: 3);
      expect(SaveService.I.gardenTotalRescues, 5);
      expect(SaveService.I.gardenDecorations, contains('rescue_lantern'));
      final third = SaveService.I.recordGardenLevelCompletion(3, rescued: 0);
      expect(third.rewards, contains('MOON DAISY SEED'));
      expect(SaveService.I.gardenSeeds['moon_daisy'], 1);
      expect(SaveService.I.gardenPlants[0]?.stage, GardenGrowthStage.mature);

      final levelThreeReplay = SaveService.I.recordGardenLevelCompletion(
        3,
        rescued: 50,
      );
      expect(levelThreeReplay.rewards, isEmpty);
      expect(SaveService.I.gardenTotalRescues, 5);
    },
  );

  test('rescue milestone decorations unlock once and remain placeable', () {
    SaveService.I.recordGardenLevelCompletion(1, rescued: 5);
    expect(SaveService.I.gardenDecorations, contains('rescue_lantern'));
    expect(SaveService.I.placeGardenDecoration('rescue_lantern', 1), isTrue);
    SaveService.I.recordGardenLevelCompletion(2, rescued: 10);
    expect(SaveService.I.gardenDecorations, contains('nebula_arch'));
    expect(SaveService.I.gardenTotalRescues, 15);
  });

  test(
    'garden plants, inventory, decor and progress persist across reload',
    () async {
      SaveService.I.buyGardenSeed('comet_rose');
      SaveService.I.plantGardenSeed('comet_rose', 2);
      SaveService.I.recordGardenLevelCompletion(1, rescued: 5);
      SaveService.I.placeGardenDecoration('rescue_lantern', 0);

      await SaveService.I.load();
      expect(SaveService.I.gardenPlants[2]?.seedId, 'comet_rose');
      expect(SaveService.I.gardenPlants[2]?.stage, GardenGrowthStage.sprout);
      expect(SaveService.I.gardenDecorations, contains('rescue_lantern'));
      expect(SaveService.I.placedGardenDecorations[0], 'rescue_lantern');
      expect(SaveService.I.gardenCompletedLevels, {1});
      expect(SaveService.I.gardenTotalRescues, 5);
    },
  );

  test('older and malformed garden data migrates to safe values', () async {
    SharedPreferences.setMockInitialValues({
      'cosmopop_v1':
          '{"coins":90,"garden":{"seeds":{"moon_daisy":2,"bad":50},'
          '"plants":{"0":{"seedId":"moon_daisy","growth":99},'
          '"8":{"seedId":"moon_daisy","growth":1},'
          '"1":{"seedId":"invalid","growth":2}},'
          '"decorations":["star_lantern","unknown"],'
          '"placedDecorations":{"0":"star_lantern","1":"unknown"},'
          '"completedLevels":[1,1,200,"bad"],"totalRescues":-4}}',
    });
    await SaveService.I.load();

    expect(SaveService.I.gardenSeeds, {'moon_daisy': 2});
    expect(SaveService.I.gardenPlants, {
      0: const GardenPlant(seedId: 'moon_daisy', growth: 3),
    });
    expect(SaveService.I.gardenDecorations, {'star_lantern'});
    expect(SaveService.I.placedGardenDecorations, {0: 'star_lantern'});
    expect(SaveService.I.gardenCompletedLevels, {1});
    expect(SaveService.I.gardenTotalRescues, 0);
  });

  testWidgets('Mimo garden screen is usable on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: GardenScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("MIMO'S GARDEN"), findsOneWidget);
    expect(find.text('Garden plots'), findsOneWidget);
    expect(find.text('Seed pouch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
