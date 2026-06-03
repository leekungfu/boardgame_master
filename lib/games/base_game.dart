import '../models/player.dart';
import '../models/game_phase.dart';
import '../models/game_session.dart';
import '../models/role.dart';

abstract class BaseGame {
  String get id;
  String get name;
  String get emoji;
  String get description;
  int get minPlayers;
  int get maxPlayers;
  List<Role> get availableRoles;

  /// Validate whether the role setup is correct before game starts.
  /// Returns null if valid, or an error message string.
  String? validateRoleSetup(List<Player> players);

  /// Build the intro phases (before first night).
  List<GamePhase> buildIntroPhases();

  /// Build phases for a single round (night → day cycle).
  List<GamePhase> buildRoundPhases(int round, List<Player> alivePlayers);

  /// Check win condition. Returns GameResult.
  GameResult checkWinCondition(List<Player> players);

  /// Create a fresh GameSession from a player list.
  GameSession createSession(List<Player> players) {
    final phases = [...buildIntroPhases(), ...buildRoundPhases(1, players)];
    return GameSession(
      gameId: id,
      players: players,
      phases: phases,
    );
  }
}

