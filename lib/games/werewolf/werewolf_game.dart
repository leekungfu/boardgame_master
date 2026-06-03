import '../../models/player.dart';
import '../../models/game_phase.dart';
import '../../models/game_session.dart';
import '../../models/role.dart';
import '../base_game.dart';
import 'werewolf_roles.dart';
import 'werewolf_presets.dart';

class WerewolfGame extends BaseGame {
  static final WerewolfGame instance = WerewolfGame._();
  WerewolfGame._();

  @override
  String get id => 'werewolf';

  @override
  String get name => 'Ma Sói';

  @override
  String get emoji => '🐺';

  @override
  String get description => 'Game suy luận kinh điển: Dân Làng vs Ma Sói.';

  @override
  int get minPlayers => 5;

  @override
  int get maxPlayers => 20;

  @override
  List<Role> get availableRoles => WerewolfRoles.all;

  // ─── T010: Auto-distribute ──────────────────────────────────────────────────

  List<Player> autoDistribute(List<Player> players, {Map<String, int>? composition}) {
    final count = players.length;
    final counts = composition ?? WerewolfPresets.table[count]?.roleCounts;
    if (counts == null) {
      throw ArgumentError('Số người chơi $count không hợp lệ (cần 5–20).');
    }

    // Build flat role list from the composition counts
    final roleList = <Role>[];
    for (final entry in counts.entries) {
      final role = availableRoles.firstWhere(
        (r) => r.id == entry.key,
        orElse: () => WerewolfRoles.villager,
      );
      for (var i = 0; i < entry.value; i++) {
        roleList.add(role);
      }
    }

    // Reconcile against the actual player count: pad short with villagers,
    // truncate if the composition has more roles than players.
    while (roleList.length < count) {
      roleList.add(WerewolfRoles.villager);
    }
    if (roleList.length > count) {
      roleList.removeRange(count, roleList.length);
    }
    roleList.shuffle();

    return List.generate(
      players.length,
      (i) => players[i].copyWith(role: roleList[i]),
    );
  }

  @override
  String? validateRoleSetup(List<Player> players) {
    if (players.length < minPlayers) return 'Cần ít nhất $minPlayers người chơi.';
    final unassigned = players.where((p) => p.role == null).length;
    if (unassigned > 0) return 'Còn $unassigned người chưa được giao vai.';
    final wolves = players.where((p) => p.role?.team == RoleTeam.werewolf).length;
    if (wolves == 0) return 'Cần ít nhất 1 Ma Sói.';
    final villagers = players.where((p) => p.role?.team == RoleTeam.villager).length;
    if (villagers == 0) return 'Cần ít nhất 1 Dân Làng.';
    return null;
  }

  @override
  List<GamePhase> buildIntroPhases() {
    return [
      const GamePhase(
        id: 'intro',
        name: 'Bắt đầu',
        description: 'Mọi người nhắm mắt lại. QT nhắc nhở luật chơi và chuẩn bị cho đêm đầu tiên.',
        scriptText: 'Chào mừng tất cả mọi người đến với trò chơi Ma Sói! Xin mời tất cả nhắm mắt lại. Không được nhìn xung quanh. Chúng ta sắp bắt đầu đêm đầu tiên...',
        phaseType: PhaseType.dayDiscussion,
        isNight: false,
      ),
    ];
  }

  @override
  List<GamePhase> buildRoundPhases(int round, List<Player> alivePlayers) {
    final hasBodyguard = alivePlayers.any((p) => p.role?.id == 'bodyguard' && p.isAlive);
    final hasSeer = alivePlayers.any((p) => p.role?.id == 'seer' && p.isAlive);
    final hasWitch = alivePlayers.any((p) => p.role?.id == 'witch' && p.isAlive);

    final nightPhases = <GamePhase>[
      GamePhase(
        id: 'night_start_$round',
        name: 'Đêm $round',
        description: 'Tất cả nhắm mắt. Làng chìm vào giấc ngủ...',
        scriptText: 'Tất cả người chơi nhắm mắt lại. Đêm $round buông xuống làng. Không ai được mở mắt hay tạo ra tiếng động...',
        phaseType: PhaseType.nightStep,
        isNight: true,
      ),
      if (hasBodyguard)
        GamePhase(
          id: 'bodyguard_$round',
          name: '🛡️ Hiệp Sĩ thức',
          description: 'Hiệp Sĩ mở mắt và chỉ vào người họ muốn bảo vệ đêm nay.',
          scriptText: 'Hiệp Sĩ, hãy mở mắt.\n\nChỉ vào người bạn muốn bảo vệ đêm nay.\n\n⚠️ Lưu ý: Không được bảo vệ cùng người đêm qua.',
          phaseType: PhaseType.nightStep,
          isNight: true,
          activeRoleIds: const ['bodyguard'],
        ),
      GamePhase(
        id: 'werewolf_$round',
        name: '🐺 Ma Sói thức',
        description: 'Ma Sói mở mắt, nhận diện nhau, thống nhất chọn 1 nạn nhân.',
        scriptText: 'Ma Sói, hãy mở mắt.\n\nNhìn nhau và nhận diện đồng đội.\n\nThống nhất chọn 1 nạn nhân và chỉ tay cho QT thấy.',
        phaseType: PhaseType.nightStep,
        isNight: true,
        durationSeconds: 30,
        activeRoleIds: const ['werewolf'],
      ),
      if (hasSeer)
        GamePhase(
          id: 'seer_$round',
          name: '🔮 Tiên Tri thức',
          description: 'Tiên Tri mở mắt, chỉ vào 1 người để kiểm tra.',
          scriptText: 'Tiên Tri, hãy mở mắt.\n\nChỉ vào người bạn muốn kiểm tra đêm nay.\n\nQT sẽ ra hiệu: 👍 nếu là Sói, 👎 nếu là Dân.',
          phaseType: PhaseType.nightStep,
          isNight: true,
          activeRoleIds: const ['seer'],
        ),
      if (hasWitch)
        GamePhase(
          id: 'witch_$round',
          name: '🧪 Phù Thủy thức',
          description: 'Phù Thủy mở mắt. QT cho biết ai bị Sói giết.',
          scriptText: 'Phù Thủy, hãy mở mắt.\n\nQT sẽ chỉ vào người bị Ma Sói chọn giết đêm nay.\n\nBạn có muốn dùng bình cứu không?\nBạn có muốn dùng bình độc không?\n\nHãy ra hiệu cho QT biết quyết định.',
          phaseType: PhaseType.nightStep,
          isNight: true,
          activeRoleIds: const ['witch'],
        ),
      GamePhase(
        id: 'night_end_$round',
        name: '🌅 Bình minh',
        description: 'Tất cả thức dậy. QT thông báo kết quả đêm.',
        scriptText: 'Tất cả người chơi mở mắt. Một đêm nữa đã qua...',
        phaseType: PhaseType.morning,
        isNight: false,
      ),
    ];

    final dayPhases = <GamePhase>[
      GamePhase(
        id: 'discussion_$round',
        name: '☀️ Thảo Luận',
        description: 'Mọi người thảo luận, suy luận, cáo buộc nhau.',
        scriptText: 'Làng thức dậy và bắt đầu thảo luận. Ai có nghi ngờ về ai? Hãy trình bày lý do của mình!',
        phaseType: PhaseType.dayDiscussion,
        isNight: false,
        durationSeconds: 180,
      ),
      GamePhase(
        id: 'vote_$round',
        name: '🗳️ Bỏ Phiếu',
        description: 'Tất cả bỏ phiếu loại 1 người.',
        scriptText: 'Đến giờ bỏ phiếu! Hãy đề cử và vote người bạn nghi ngờ là Ma Sói.',
        phaseType: PhaseType.dayVoting,
        isNight: false,
      ),
    ];

    return [...nightPhases, ...dayPhases];
  }

  @override
  GameResult checkWinCondition(List<Player> players) {
    final aliveWolves = players.where((p) => p.isAlive && p.role?.team == RoleTeam.werewolf).length;
    final aliveVillagers = players.where((p) => p.isAlive && p.role?.team == RoleTeam.villager).length;
    if (aliveWolves == 0) return GameResult.villagerWin;
    if (aliveWolves >= aliveVillagers) return GameResult.werewolfWin;
    return GameResult.ongoing;
  }
}
