import '../../core/constants.dart';
import '../../core/save_service.dart';

enum PowerupKind { bomb, rainbow, lightning, rocket }

class PowerupDefinition {
  final PowerupKind kind;
  final String id;
  final int price;
  final bool requiresTarget;
  final int unlockLevel;

  const PowerupDefinition({
    required this.kind,
    required this.id,
    required this.price,
    required this.requiresTarget,
    this.unlockLevel = 1,
  });
}

class PowerupLogic {
  static const definitions = <String, PowerupDefinition>{
    'bomb': PowerupDefinition(
      kind: PowerupKind.bomb,
      id: 'bomb',
      price: 75,
      requiresTarget: true,
    ),
    'rainbow': PowerupDefinition(
      kind: PowerupKind.rainbow,
      id: 'rainbow',
      price: 100,
      requiresTarget: false,
    ),
    'lightning': PowerupDefinition(
      kind: PowerupKind.lightning,
      id: 'lightning',
      price: 125,
      requiresTarget: true,
      unlockLevel: 10,
    ),
    'rocket': PowerupDefinition(
      kind: PowerupKind.rocket,
      id: 'rocket',
      price: 100,
      requiresTarget: true,
    ),
  };

  static PowerupDefinition? definition(String id) => definitions[id];

  static bool isUnlocked(
    String id, {
    required GameMode mode,
    required int level,
  }) {
    final item = definition(id);
    if (item == null) return false;
    if (id == 'lightning' && mode == GameMode.level) {
      return level >= item.unlockLevel;
    }
    return true;
  }

  static int count(String id) => SaveService.I.powerups[id] ?? 0;

  static bool consume(String id) {
    if (!definitions.containsKey(id)) return false;
    return SaveService.I.usePowerup(id);
  }

  static bool purchase(String id) {
    final item = definition(id);
    return item != null && SaveService.I.purchasePowerup(id, item.price);
  }
}
