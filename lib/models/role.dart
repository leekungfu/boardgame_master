enum RoleTeam { villager, werewolf, neutral }

class Role {
  final String id;
  final String name;
  final String emoji;
  final RoleTeam team;
  final String description;
  final bool hasNightAction;
  final int nightOrder; // lower = acts earlier at night (0 = no night action)

  const Role({
    required this.id,
    required this.name,
    required this.emoji,
    required this.team,
    required this.description,
    this.hasNightAction = false,
    this.nightOrder = 0,
  });
}

