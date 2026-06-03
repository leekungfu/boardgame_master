import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/ability_state.dart';
import '../models/night_action_record.dart';
import '../models/vote_tally.dart';
import '../games/game_registry.dart';

const _kSessionKey = 'active_game_session';
const _kThemeModeKey = 'theme_mode';

class PersistenceService {
  /// Persist the selected theme mode as one of: 'system' | 'light' | 'dark'.
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode);
  }

  /// Load the persisted theme mode name, or null if never set.
  static Future<String?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeModeKey);
  }

  static Future<void> saveSession(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(session.toJson());
    await prefs.setString(_kSessionKey, json);
  }

  static Future<GameSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessionKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _fromJson(json);
    } catch (_) {
      await prefs.remove(_kSessionKey);
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
  }

  static GameSession? _fromJson(Map<String, dynamic> json) {
    final gameId = json['gameId'] as String;
    final game = GameRegistry.getById(gameId);
    if (game == null) return null;

    final playersJson = json['players'] as List<dynamic>;
    final players = playersJson.map((p) {
      final pm = p as Map<String, dynamic>;
      final roleId = pm['roleId'] as String?;
      final role = roleId != null ? game.availableRoles.firstWhere((r) => r.id == roleId) : null;
      return Player(
        id: pm['id'] as String,
        name: pm['name'] as String,
        isAlive: pm['isAlive'] as bool? ?? true,
        role: role,
      );
    }).toList();

    final round = json['round'] as int? ?? 1;
    final abilityState = AbilityState.fromJson(json['abilityState'] as Map<String, dynamic>? ?? {});
    final nightLog = (json['nightLog'] as List<dynamic>?)
            ?.map((e) => NightActionRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final currentVoteTallyJson = json['currentVoteTally'] as Map<String, dynamic>?;
    final deathHistory = (json['deathHistory'] as List<dynamic>?)
            ?.map((e) => DeathEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final alivePlayers = players.where((p) => p.isAlive).toList();
    final phases = [...game.buildIntroPhases(), ...game.buildRoundPhases(round, alivePlayers)];
    final currentPhaseIndex = json['currentPhaseIndex'] as int? ?? 0;

    final session = GameSession(
      gameId: gameId,
      players: players,
      phases: phases,
      currentPhaseIndex: currentPhaseIndex.clamp(0, phases.length - 1),
      round: round,
      result: GameResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => GameResult.ongoing,
      ),
      qtNote: json['qtNote'] as String?,
      abilityState: abilityState,
      nightLog: nightLog,
      currentVoteTally: currentVoteTallyJson != null ? VoteTally.fromJson(currentVoteTallyJson) : null,
      deathHistory: deathHistory,
    );
    return session;
  }
}
