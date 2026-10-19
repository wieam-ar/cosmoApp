enum BossWeakness { burn, steam, mud, bloom }

class BossPhaseDefinition {
  final BossWeakness weakness;
  final String title;
  final String hint;

  const BossPhaseDefinition({
    required this.weakness,
    required this.title,
    required this.hint,
  });
}

class BossEncounterDefinition {
  final String id;
  final String name;
  final String title;
  final List<BossPhaseDefinition> phases;
  final int attackEveryTurns;

  const BossEncounterDefinition({
    required this.id,
    required this.name,
    required this.title,
    required this.phases,
    required this.attackEveryTurns,
  });

  int get health => phases.length;
}

const kVoidKingEncounter = BossEncounterDefinition(
  id: 'void_king',
  name: 'THE VOID KING',
  title: 'THE ECLIPSE CORE',
  phases: [
    BossPhaseDefinition(
      weakness: BossWeakness.burn,
      title: 'EMBER SHIELD',
      hint: 'A BURN reaction can crack the ember shield.',
    ),
    BossPhaseDefinition(
      weakness: BossWeakness.steam,
      title: 'VAPOR SHIELD',
      hint: 'A STEAM reaction can cloud the core.',
    ),
    BossPhaseDefinition(
      weakness: BossWeakness.mud,
      title: 'STONE SHIELD',
      hint: 'A MUD reaction can weigh the core down.',
    ),
    BossPhaseDefinition(
      weakness: BossWeakness.bloom,
      title: 'ROOT SHIELD',
      hint: 'A BLOOM reaction can break through the final shield.',
    ),
  ],
  attackEveryTurns: 2,
);

const List<BossEncounterDefinition> kBossEncounters = [kVoidKingEncounter];
