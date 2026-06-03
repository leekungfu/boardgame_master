import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/night_action_record.dart';
import '../models/vote_tally.dart';
import '../games/base_game.dart';
import '../games/game_registry.dart';
import '../games/werewolf/werewolf_game.dart';
import 'persistence_service.dart';

const _uuid = Uuid();

// ─── Setup state ──────────────────────────────────────────────────────────────

class SetupState {
  final BaseGame? selectedGame;
  final List<Player> players;

  const SetupState({this.selectedGame, this.players = const []});

  SetupState copyWith({BaseGame? selectedGame, List<Player>? players}) {
    return SetupState(selectedGame: selectedGame ?? this.selectedGame, players: players ?? this.players);
  }
}

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState());

  void selectGame(BaseGame game) => state = state.copyWith(selectedGame: game, players: []);

  void addPlayer(String name) => state = state.copyWith(
      players: [...state.players, Player(id: _uuid.v4(), name: name.trim())]);

  void removePlayer(String id) =>
      state = state.copyWith(players: state.players.where((p) => p.id != id).toList());

  void renamePlayer(String id, String newName) => state = state.copyWith(
      players: state.players.map((p) => p.id == id ? p.copyWith(name: newName) : p).toList());

  void assignRole(String playerId, Role role) => state = state.copyWith(
      players: state.players.map((p) => p.id == playerId ? p.copyWith(role: role) : p).toList());

  void clearRoles() => state = state.copyWith(
      players: state.players.map((p) => Player(id: p.id, name: p.name)).toList());

  void reorderPlayers(List<Player> newOrder) => state = state.copyWith(players: newOrder);

  void reset() => state = const SetupState();

  void autoDistribute([Map<String, int>? composition]) {
    final game = state.selectedGame;
    if (game == null) return;
    if (game is WerewolfGame) {
      try {
        final distributed = game.autoDistribute(state.players, composition: composition);
        state = state.copyWith(players: distributed);
      } catch (_) {}
    }
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((_) => SetupNotifier());

// ─── Game session state ───────────────────────────────────────────────────────

/// Immutable capture of everything needed to revert one moderator action:
/// the [GameSession] plus the transient in-progress night record that lives
/// outside the session. Both captured types are immutable (copyWith), so a
/// reference capture is a safe snapshot.
class _GameSnapshot {
  final GameSession session;
  final NightActionRecord? pendingNight;

  const _GameSnapshot(this.session, this.pendingNight);
}

class GameNotifier extends StateNotifier<GameSession?> {
  GameNotifier() : super(null) {
    _tryRestore();
  }

  NightActionRecord? _pendingNight;

  // ─── Undo history ───────────────────────────────────────────────────────────
  // In-memory only (not persisted). The most recent reversible action is on top.
  static const int _maxUndo = 50;
  final List<_GameSnapshot> _undoStack = [];

  /// True when there is at least one reversible action to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Capture the current state before a mutating action. Called at the start of
  /// every reversible mutator. No-op when there is no active session.
  void _pushSnapshot() {
    final s = state;
    if (s == null) return;
    _undoStack.add(_GameSnapshot(s, _pendingNight));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  /// Revert the most recent reversible action, restoring both the session and
  /// the transient pending-night record. No-op when nothing is reversible.
  void undo() {
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    _pendingNight = snap.pendingNight;
    state = snap.session;
    _save();
  }

  Future<void> _tryRestore() async {
    final session = await PersistenceService.restoreSession();
    if (session != null) state = session;
  }

  void startGame(GameSession session) {
    _undoStack.clear();
    state = session;
    _save();
  }

  void nextPhase() {
    final s = state;
    if (s == null || !s.hasNextPhase) return;
    _pushSnapshot();
    state = s.copyWith(currentPhaseIndex: s.currentPhaseIndex + 1);
    _save();
  }

  void prevPhase() {
    final s = state;
    if (s == null || s.currentPhaseIndex <= 0) return;
    _pushSnapshot();
    state = s.copyWith(currentPhaseIndex: s.currentPhaseIndex - 1);
    _save();
  }

  void killPlayer(String playerId) {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    final players = s.players.map((p) => p.id == playerId ? p.copyWith(isAlive: false) : p).toList();
    final game = GameRegistry.getById(s.gameId);
    final result = game?.checkWinCondition(players) ?? s.result;
    state = s.copyWith(
      players: players,
      deathHistory: [
        ...s.deathHistory,
        DeathEvent(playerId: playerId, round: s.round, cause: DeathCause.manualKill),
      ],
      result: result,
    );
    _save();
  }

  void revivePlayer(String playerId) {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    state = s.copyWith(
      players: s.players.map((p) => p.id == playerId ? p.copyWith(isAlive: true) : p).toList(),
      result: GameResult.ongoing,
    );
    _save();
  }

  /// Retained for API compatibility — the unified [undo] supersedes the old
  /// death-only undo. Undoing the most recent action after a death restores the
  /// pre-death snapshot (player revived, death history shortened, win
  /// re-evaluated automatically because the snapshot carries the prior result).
  void undoLastDeath() => undo();

  void nextRound(BaseGame game) {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    final result = game.checkWinCondition(s.players);
    if (result != GameResult.ongoing) {
      state = s.copyWith(result: result);
      _save();
      return;
    }
    final newRound = s.round + 1;
    final newPhases = [...s.phases, ...game.buildRoundPhases(newRound, s.alivePlayers)];
    state = s.copyWith(
      round: newRound,
      phases: newPhases,
      currentPhaseIndex: s.currentPhaseIndex + 1,
    );
    _save();
  }

  void updateNote(String note) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(qtNote: note);
    _save();
  }

  void endGame() {
    _undoStack.clear();
    state = null;
    PersistenceService.clearSession();
  }

  // ─── Night action recording ───────────────────────────────────────────────

  void beginNightAction(int round) {
    // Idempotent per round: only create a fresh record at the first night step.
    // Subsequent night steps (wolf → seer → witch) must keep accumulating into
    // the same record, otherwise earlier actions (e.g. the wolf kill) are lost.
    if (_pendingNight?.round == round) return;
    _pendingNight = NightActionRecord(round: round);
    final s = state;
    if (s != null) state = s.copyWith(currentNightWolfTarget: null);
  }

  void recordWolfKill(String playerId) {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(wolfTarget: playerId);
    final s = state;
    if (s == null) return;
    state = s.copyWith(currentNightWolfTarget: playerId);
  }

  void recordBodyguardProtect(String playerId) {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(bodyguardTarget: playerId);
    final s = state;
    if (s == null) return;
    state = s.copyWith(abilityState: s.abilityState.copyWith(lastBodyguardTarget: playerId));
  }

  void recordWitchSave(String playerId) {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(witchSaveTarget: playerId);
    final s = state;
    if (s == null) return;
    state = s.copyWith(abilityState: s.abilityState.copyWith(witchSaveUsed: true));
  }

  void recordWitchKill(String playerId) {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(witchKillTarget: playerId);
    final s = state;
    if (s == null) return;
    state = s.copyWith(abilityState: s.abilityState.copyWith(witchKillUsed: true));
  }

  void clearWitchKill() {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(witchKillTarget: null);
  }

  void recordSeer(String playerId, bool isWolf) {
    if (_pendingNight == null) return;
    _pushSnapshot();
    _pendingNight = _pendingNight!.copyWith(seerTarget: playerId, seerResultIsWolf: isWolf);
  }

  void resolveNight(BaseGame game) {
    final s = state;
    final night = _pendingNight;
    if (s == null || night == null) return;
    _pushSnapshot();
    _pendingNight = null;

    final updatedNight = night.copyWith(resolved: true);
    final died = night.resolveDeaths();

    var players = s.players.toList();
    var deathHistory = s.deathHistory.toList();
    var abilityState = s.abilityState;
    var hunterPending = false;

    for (final id in died) {
      players = players.map((p) => p.id == id ? p.copyWith(isAlive: false) : p).toList();
      final cause = night.witchKillTarget == id ? DeathCause.witchPoison : DeathCause.wolfKill;
      deathHistory = [...deathHistory, DeathEvent(playerId: id, round: s.round, cause: cause)];
      final dead = players.firstWhere((p) => p.id == id);
      if (dead.role?.id == 'hunter') hunterPending = true;
    }
    if (hunterPending) {
      abilityState = abilityState.copyWith(hunterShotPending: true);
    }

    state = s.copyWith(
      players: players,
      nightLog: [...s.nightLog, updatedNight],
      deathHistory: deathHistory,
      abilityState: abilityState,
      result: game.checkWinCondition(players),
      currentNightWolfTarget: null,
    );
    _save();
  }

  // ─── Hunter shot ──────────────────────────────────────────────────────────

  void recordHunterShot(String targetPlayerId, BaseGame game) {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    final players =
        s.players.map((p) => p.id == targetPlayerId ? p.copyWith(isAlive: false) : p).toList();
    state = s.copyWith(
      players: players,
      deathHistory: [
        ...s.deathHistory,
        DeathEvent(playerId: targetPlayerId, round: s.round, cause: DeathCause.hunterShot),
      ],
      abilityState: s.abilityState.copyWith(
        hunterShotPending: false,
        hunterShotTarget: targetPlayerId,
      ),
      result: game.checkWinCondition(players),
    );
    _save();
  }

  // ─── Day voting ───────────────────────────────────────────────────────────

  void beginDayVote() {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    state = s.copyWith(currentVoteTally: VoteTally(round: s.round));
  }

  void nominatePlayer(String playerId) {
    final s = state;
    if (s == null || s.currentVoteTally == null) return;
    final tally = s.currentVoteTally!;
    final already = tally.nominations.any((e) => e.playerId == playerId);
    if (already) return;
    _pushSnapshot();
    state = s.copyWith(
      currentVoteTally: tally.copyWith(
        nominations: [...tally.nominations, VoteEntry(playerId: playerId)],
      ),
    );
  }

  void setVoteCount(String playerId, int count) {
    final s = state;
    if (s == null || s.currentVoteTally == null) return;
    _pushSnapshot();
    final tally = s.currentVoteTally!;
    state = s.copyWith(
      currentVoteTally: tally.copyWith(
        nominations: tally.nominations
            .map((e) => e.playerId == playerId ? e.copyWith(voteCount: count) : e)
            .toList(),
      ),
    );
  }

  void resolveVote() {
    final s = state;
    if (s == null || s.currentVoteTally == null) return;
    _pushSnapshot();
    state = s.copyWith(currentVoteTally: s.currentVoteTally!.resolve());
  }

  void confirmExecution(String playerId, BaseGame game) {
    final s = state;
    if (s == null) return;
    _pushSnapshot();
    final target = s.players.firstWhere((p) => p.id == playerId);
    if (target.role?.id == 'fool' && !s.abilityState.foolImmunityUsed) {
      state = s.copyWith(abilityState: s.abilityState.copyWith(foolImmunityUsed: true));
      _save();
      return;
    }
    var abilityState = s.abilityState;
    if (target.role?.id == 'hunter') {
      abilityState = abilityState.copyWith(hunterShotPending: true);
    }
    final players =
        s.players.map((p) => p.id == playerId ? p.copyWith(isAlive: false) : p).toList();
    state = s.copyWith(
      players: players,
      deathHistory: [
        ...s.deathHistory,
        DeathEvent(playerId: playerId, round: s.round, cause: DeathCause.execution),
      ],
      abilityState: abilityState,
      result: game.checkWinCondition(players),
    );
    _save();
  }

  void _save() {
    final s = state;
    if (s != null) PersistenceService.saveSession(s);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameSession?>((_) => GameNotifier());
