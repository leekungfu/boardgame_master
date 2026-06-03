import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boardgame_master/models/game_session.dart';
import 'package:boardgame_master/models/player.dart';
import 'package:boardgame_master/models/game_phase.dart';
import 'package:boardgame_master/models/night_action_record.dart';
import 'package:boardgame_master/models/vote_tally.dart';
import 'package:boardgame_master/providers/game_provider.dart';
import 'package:boardgame_master/games/werewolf/werewolf_game.dart';
import 'package:boardgame_master/games/werewolf/werewolf_roles.dart';

GameSession _makeSession({List<Player>? players}) {
  final ps = players ??
      [
        Player(id: 'w1', name: 'Wolf1', role: WerewolfRoles.werewolf),
        Player(id: 'v1', name: 'Villager1', role: WerewolfRoles.villager),
        Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
      ];
  return GameSession(
    gameId: 'werewolf',
    players: ps,
    phases: [
      const GamePhase(
          id: 'intro',
          name: 'Intro',
          description: '',
          phaseType: PhaseType.dayDiscussion,
          isNight: false),
    ],
  );
}

GameNotifier _makeNotifier(ProviderContainer container, GameSession session) {
  final notifier = container.read(gameProvider.notifier);
  notifier.startGame(session);
  return notifier;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('killPlayer', () {
    test('marks player dead immutably', () {
      final container = ProviderContainer();
      final session = _makeSession();
      final notifier = _makeNotifier(container, session);

      final before = container.read(gameProvider)!;
      notifier.killPlayer('v1');
      final after = container.read(gameProvider)!;

      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse);
      expect(before.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
    });

    test('state lists are not shared between before and after', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      final before = container.read(gameProvider)!;
      notifier.killPlayer('v1');
      final after = container.read(gameProvider)!;
      expect(identical(before.players, after.players), isFalse);
    });

    test('detects werewolf win when all wolves killed', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.killPlayer('w1');
      final after = container.read(gameProvider)!;
      expect(after.result, GameResult.villagerWin);
    });
  });

  group('revivePlayer', () {
    test('restores dead player to alive', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.killPlayer('v1');
      notifier.revivePlayer('v1');
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
    });
  });

  group('undoLastDeath', () {
    test('noop when deathHistory is empty', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.undoLastDeath();
      final after = container.read(gameProvider)!;
      expect(after.players.every((p) => p.isAlive), isTrue);
    });

    test('restores most recently killed player', () {
      final container = ProviderContainer();
      final session = _makeSession();
      final notifier = _makeNotifier(container, session);
      notifier.killPlayer('v1');
      notifier.killPlayer('v2');
      notifier.undoLastDeath();
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v2').isAlive, isTrue);
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse);
    });
  });

  group('resolveNight', () {
    final game = WerewolfGame.instance;

    test('wolf target dies when not protected', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse);
    });

    test('wolf target survives when bodyguard protects', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      notifier.recordBodyguardProtect('v1');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
    });

    test('wolf target survives when witch saves', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      notifier.recordWitchSave('v1');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
    });

    test('witch kill target dies', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWitchKill('v2');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v2').isAlive, isFalse);
    });

    test('noop when pendingNight is null (beginNightAction not called)', () {
      final container = ProviderContainer();
      final session = _makeSession();
      final notifier = _makeNotifier(container, session);
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.every((p) => p.isAlive), isTrue);
    });

    test('beginNightAction is idempotent within a round — actions accumulate across steps', () {
      // Regression: each night step (bodyguard → wolf → seer → witch) calls
      // beginNightAction. It must NOT reset the record, or the wolf kill is lost.
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1); // bodyguard step
      notifier.recordBodyguardProtect('v2');
      notifier.beginNightAction(1); // wolf step
      notifier.recordWolfKill('v1');
      notifier.beginNightAction(1); // seer step
      notifier.recordSeer('w1', true);
      notifier.beginNightAction(1); // witch step (no action)
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse,
          reason: 'wolf target must die even though witch step ran after');
      expect(after.players.firstWhere((p) => p.id == 'v2').isAlive, isTrue);
      expect(after.nightLog.first.wolfTarget, 'v1');
      expect(after.nightLog.first.bodyguardTarget, 'v2');
      expect(after.nightLog.first.seerTarget, 'w1');
    });

    test('new round resets the pending record', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      notifier.resolveNight(game);
      notifier.beginNightAction(2); // new round → fresh record
      notifier.recordWolfKill('v2');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.nightLog.length, 2);
      expect(after.nightLog.last.wolfTarget, 'v2');
    });

    test('nightLog grows after resolve', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.nightLog.length, 1);
      expect(after.nightLog.first.resolved, isTrue);
    });

    test('clearWitchKill removes kill target so target survives', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWitchKill('v2');
      notifier.clearWitchKill();
      notifier.resolveNight(game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v2').isAlive, isTrue);
    });
  });

  group('confirmExecution', () {
    final game = WerewolfGame.instance;

    test('player dies on execution', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.confirmExecution('v1', game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse);
    });

    test('fool survives first execution (foolImmunityUsed becomes true)', () {
      final players = [
        Player(id: 'w1', name: 'Wolf', role: WerewolfRoles.werewolf),
        Player(id: 'f1', name: 'Fool', role: WerewolfRoles.fool),
        Player(id: 'v1', name: 'Villager', role: WerewolfRoles.villager),
        Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
      ];
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession(players: players));
      notifier.confirmExecution('f1', game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'f1').isAlive, isTrue);
      expect(after.abilityState.foolImmunityUsed, isTrue);
    });

    test('fool dies on second execution', () {
      final players = [
        Player(id: 'w1', name: 'Wolf', role: WerewolfRoles.werewolf),
        Player(id: 'f1', name: 'Fool', role: WerewolfRoles.fool),
        Player(id: 'v1', name: 'Villager', role: WerewolfRoles.villager),
        Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
      ];
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession(players: players));
      notifier.confirmExecution('f1', game);
      notifier.confirmExecution('f1', game);
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'f1').isAlive, isFalse);
    });

    test('hunter shot pending after hunter execution', () {
      final players = [
        Player(id: 'w1', name: 'Wolf', role: WerewolfRoles.werewolf),
        Player(id: 'h1', name: 'Hunter', role: WerewolfRoles.hunter),
        Player(id: 'v1', name: 'Villager', role: WerewolfRoles.villager),
        Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
      ];
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession(players: players));
      notifier.confirmExecution('h1', game);
      final after = container.read(gameProvider)!;
      expect(after.abilityState.hunterShotPending, isTrue);
    });
  });

  group('setVoteCount', () {
    test('updates vote count immutably', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginDayVote();
      notifier.nominatePlayer('v1');
      final before = container.read(gameProvider)!;
      final beforeEntry = before.currentVoteTally!.nominations.first;
      notifier.setVoteCount('v1', 3);
      final after = container.read(gameProvider)!;
      expect(after.currentVoteTally!.nominations.first.voteCount, 3);
      expect(beforeEntry.voteCount, 0);
    });
  });

  group('nextRound', () {
    final game = WerewolfGame.instance;

    test('appends new phases and advances index', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      final before = container.read(gameProvider)!;
      notifier.nextRound(game);
      final after = container.read(gameProvider)!;
      expect(after.phases.length, greaterThan(before.phases.length));
      expect(after.currentPhaseIndex, before.currentPhaseIndex + 1);
    });

    test('detects win condition before advancing round', () {
      final players = [
        Player(id: 'v1', name: 'Villager1', role: WerewolfRoles.villager),
        Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
      ];
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession(players: players));
      notifier.nextRound(game);
      final after = container.read(gameProvider)!;
      expect(after.result, GameResult.villagerWin);
    });
  });

  group('VoteTally.resolve', () {
    test('returns new instance, marks winner', () {
      final tally = VoteTally(
        round: 1,
        nominations: [
          const VoteEntry(playerId: 'a', voteCount: 3),
          const VoteEntry(playerId: 'b', voteCount: 1),
        ],
      );
      final resolved = tally.resolve();
      expect(resolved.resolved, isTrue);
      expect(resolved.executedPlayerId, 'a');
      expect(resolved.wasTied, isFalse);
      expect(tally.resolved, isFalse);
    });

    test('detects tie correctly', () {
      final tally = VoteTally(
        round: 1,
        nominations: [
          const VoteEntry(playerId: 'a', voteCount: 2),
          const VoteEntry(playerId: 'b', voteCount: 2),
        ],
      );
      final resolved = tally.resolve();
      expect(resolved.wasTied, isTrue);
      expect(resolved.executedPlayerId, isNull);
    });
  });

  group('undo (unified per-phase)', () {
    final game = WerewolfGame.instance;

    GameSession twoPhaseSession({List<Player>? players}) => GameSession(
          gameId: 'werewolf',
          players: players ??
              [
                Player(id: 'w1', name: 'Wolf1', role: WerewolfRoles.werewolf),
                Player(id: 'v1', name: 'Villager1', role: WerewolfRoles.villager),
                Player(id: 'v2', name: 'Villager2', role: WerewolfRoles.villager),
              ],
          phases: const [
            GamePhase(id: 'p0', name: 'P0', description: '', phaseType: PhaseType.nightStep, isNight: true),
            GamePhase(id: 'p1', name: 'P1', description: '', phaseType: PhaseType.dayDiscussion),
          ],
        );

    test('canUndo is false on a fresh game (U3)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      expect(notifier.canUndo, isFalse);
    });

    test('undo clears a just-recorded wolf target and restores pending state (U1)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.beginNightAction(1);
      notifier.recordWolfKill('v1');
      expect(container.read(gameProvider)!.currentNightWolfTarget, 'v1');
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(container.read(gameProvider)!.currentNightWolfTarget, isNull);
    });

    test('undo of nextPhase returns to the previous phase (U5)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, twoPhaseSession());
      expect(container.read(gameProvider)!.currentPhaseIndex, 0);
      notifier.nextPhase();
      expect(container.read(gameProvider)!.currentPhaseIndex, 1);
      notifier.undo();
      expect(container.read(gameProvider)!.currentPhaseIndex, 0);
    });

    test('undo of a win-triggering kill revives player and clears the win (U6/U8)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.killPlayer('w1'); // all wolves dead → villager win
      expect(container.read(gameProvider)!.result, GameResult.villagerWin);
      notifier.undo();
      final after = container.read(gameProvider)!;
      expect(after.players.firstWhere((p) => p.id == 'w1').isAlive, isTrue);
      expect(after.result, GameResult.ongoing);
    });

    test('repeated undo reverts in reverse order until exhausted (U2/U4)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.killPlayer('v1');
      notifier.killPlayer('v2');
      notifier.undo(); // revert kill v2
      expect(container.read(gameProvider)!.players.firstWhere((p) => p.id == 'v2').isAlive, isTrue);
      notifier.undo(); // revert kill v1
      expect(container.read(gameProvider)!.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
      expect(notifier.canUndo, isFalse);
      notifier.undo(); // no-op when exhausted
      expect(container.read(gameProvider)!.players.every((p) => p.isAlive), isTrue);
    });

    test('undo of confirmExecution restores the executed player (U7/U8)', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.confirmExecution('v1', game);
      expect(container.read(gameProvider)!.players.firstWhere((p) => p.id == 'v1').isAlive, isFalse);
      notifier.undo();
      expect(container.read(gameProvider)!.players.firstWhere((p) => p.id == 'v1').isAlive, isTrue);
    });

    test('startGame clears undo history', () {
      final container = ProviderContainer();
      final notifier = _makeNotifier(container, _makeSession());
      notifier.killPlayer('v1');
      expect(notifier.canUndo, isTrue);
      notifier.startGame(_makeSession());
      expect(notifier.canUndo, isFalse);
    });
  });

  group('NightActionRecord', () {
    test('copyWith preserves unmodified fields', () {
      const r = NightActionRecord(round: 1, wolfTarget: 'w');
      final r2 = r.copyWith(bodyguardTarget: 'b');
      expect(r2.wolfTarget, 'w');
      expect(r2.bodyguardTarget, 'b');
      expect(r2.round, 1);
    });

    test('copyWith can clear nullable fields', () {
      const r = NightActionRecord(round: 1, wolfTarget: 'w', witchKillTarget: 'x');
      final r2 = r.copyWith(witchKillTarget: null);
      expect(r2.witchKillTarget, isNull);
      expect(r2.wolfTarget, 'w');
    });
  });
}
