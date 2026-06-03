enum PhaseType { nightStep, morning, dayDiscussion, dayVoting, special }

class GamePhase {
  final String id;
  final String name;
  final String description;
  final String scriptText;
  final PhaseType phaseType;
  final bool isNight;
  final int durationSeconds;
  final List<String> activeRoleIds;

  const GamePhase({
    required this.id,
    required this.name,
    required this.description,
    this.scriptText = '',
    this.phaseType = PhaseType.dayDiscussion,
    this.isNight = false,
    this.durationSeconds = 0,
    this.activeRoleIds = const [],
  });
}
