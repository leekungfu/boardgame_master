import 'player.dart';
import 'game_phase.dart';
import 'ability_state.dart';
import 'night_action_record.dart';
import 'vote_tally.dart';

enum GameResult { villagerWin, werewolfWin, ongoing }

enum DeathCause { wolfKill, witchPoison, execution, hunterShot, manualKill }

class DeathEvent {
  final String playerId;
  final int round;
  final DeathCause cause;

  const DeathEvent({required this.playerId, required this.round, required this.cause});

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'round': round,
        'cause': cause.name,
      };

  factory DeathEvent.fromJson(Map<String, dynamic> j) => DeathEvent(
        playerId: j['playerId'] as String,
        round: j['round'] as int,
        cause: DeathCause.values.firstWhere((e) => e.name == j['cause'], orElse: () => DeathCause.wolfKill),
      );
}

class GameSession {
  final String gameId;
  final List<Player> players;
  final List<GamePhase> phases;
  final int currentPhaseIndex;
  final int round;
  final GameResult result;
  final String? qtNote;
  final AbilityState abilityState;
  final List<NightActionRecord> nightLog;
  final VoteTally? currentVoteTally;
  final List<DeathEvent> deathHistory;
  final String? currentNightWolfTarget;

  const GameSession({
    required this.gameId,
    required this.players,
    required this.phases,
    this.currentPhaseIndex = 0,
    this.round = 1,
    this.result = GameResult.ongoing,
    this.qtNote,
    this.abilityState = const AbilityState(),
    this.nightLog = const [],
    this.currentVoteTally,
    this.deathHistory = const [],
    this.currentNightWolfTarget,
  });

  bool get isGameOver => result != GameResult.ongoing;
  GamePhase get currentPhase => phases[currentPhaseIndex];
  List<Player> get alivePlayers => players.where((p) => p.isAlive).toList();
  bool get hasNextPhase => currentPhaseIndex < phases.length - 1;

  GameSession copyWith({
    List<Player>? players,
    List<GamePhase>? phases,
    int? currentPhaseIndex,
    int? round,
    GameResult? result,
    Object? qtNote = _s,
    AbilityState? abilityState,
    List<NightActionRecord>? nightLog,
    Object? currentVoteTally = _s,
    List<DeathEvent>? deathHistory,
    Object? currentNightWolfTarget = _s,
  }) {
    return GameSession(
      gameId: gameId,
      players: players ?? List.from(this.players),
      phases: phases ?? List.from(this.phases),
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      round: round ?? this.round,
      result: result ?? this.result,
      qtNote: qtNote == _s ? this.qtNote : qtNote as String?,
      abilityState: abilityState ?? this.abilityState,
      nightLog: nightLog ?? List.from(this.nightLog),
      currentVoteTally: currentVoteTally == _s ? this.currentVoteTally : currentVoteTally as VoteTally?,
      deathHistory: deathHistory ?? List.from(this.deathHistory),
      currentNightWolfTarget:
          currentNightWolfTarget == _s ? this.currentNightWolfTarget : currentNightWolfTarget as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'currentPhaseIndex': currentPhaseIndex,
        'round': round,
        'result': result.name,
        'qtNote': qtNote,
        'players': players.map((p) => {
              'id': p.id,
              'name': p.name,
              'isAlive': p.isAlive,
              'roleId': p.role?.id,
            }).toList(),
        'abilityState': abilityState.toJson(),
        'nightLog': nightLog.map((r) => r.toJson()).toList(),
        'currentVoteTally': currentVoteTally?.toJson(),
        'deathHistory': deathHistory.map((e) => e.toJson()).toList(),
      };
}

const _s = Object();
