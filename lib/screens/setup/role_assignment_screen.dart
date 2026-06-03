import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/role_icons.dart';
import '../../theme/app_gradients.dart';
import '../../models/player.dart';
import '../../models/role.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/atmospheric_background.dart';
import '../../widgets/role_card_widget.dart';
import '../../games/werewolf/werewolf_presets.dart';
import '../../games/werewolf/werewolf_roles.dart';
import '../game/game_master_screen.dart';

class RoleAssignmentScreen extends ConsumerStatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  ConsumerState<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends ConsumerState<RoleAssignmentScreen> {
  // Editable suggested composition (roleId → count). Initialised lazily from the
  // preset for the current player count; the QT can then tweak it before distributing.
  Map<String, int>? _composition;
  int? _compositionForCount;
  bool _suggestionExpanded = false; // collapsed by default to save space

  static const List<String> _roleOrder = [
    'werewolf', 'wolf_cub', 'minion', 'sorcerer', 'white_wolf', // wolves
    'bodyguard', 'guardian_angel', 'seer', 'apprentice_seer', 'detective', 'witch', // night villagers
    'hunter', 'fool', 'cupid', 'elder', 'prince', 'mayor', 'little_girl', 'scapegoat', // other villagers
    'cursed', 'serial_killer', 'tanner', 'villager', // neutral + plain
  ];

  void _ensureComposition(int playerCount) {
    if (_composition != null && _compositionForCount == playerCount) return;
    final preset = WerewolfPresets.table[playerCount];
    _composition = Map<String, int>.from(preset?.roleCounts ?? const {});
    _compositionForCount = playerCount;
  }

  int get _compositionTotal => (_composition ?? {}).values.fold(0, (s, v) => s + v);

  Map<String, int> get _roleCounts {
    final counts = <String, int>{};
    for (final p in ref.read(setupProvider).players) {
      if (p.role != null) counts[p.role!.id] = (counts[p.role!.id] ?? 0) + 1;
    }
    return counts;
  }

  String _balanceLabel(List<Player> players) {
    final wolves = players.where((p) => p.role?.team == RoleTeam.werewolf).length;
    final villagers =
        players.where((p) => p.role?.team != RoleTeam.werewolf && p.role != null).length;
    if (wolves == 0 && villagers == 0) return '';
    final balanced = wolves < villagers;
    return 'Ma Sói: $wolves  |  Làng: $villagers${balanced ? "  — cân bằng" : "  — mất cân bằng!"}';
  }

  Color _balanceColor(List<Player> players) {
    final wolves = players.where((p) => p.role?.team == RoleTeam.werewolf).length;
    final villagers =
        players.where((p) => p.role?.team != RoleTeam.werewolf && p.role != null).length;
    return wolves < villagers ? AppTheme.accentGreen : AppTheme.accentRed;
  }

  Widget _buildPresetPanel(int playerCount) {
    if (playerCount < 1) return const SizedBox.shrink();
    _ensureComposition(playerCount);
    final comp = _composition!;
    final total = _compositionTotal;
    final balanced = total == playerCount;

    final entries = comp.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final ia = _roleOrder.indexOf(a.key);
        final ib = _roleOrder.indexOf(b.key);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible, toggles collapse
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => setState(() => _suggestionExpanded = !_suggestionExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Gợi ý đội hình',
                          style: AppTheme.cinzelDisplay(14, color: AppTheme.accent)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (balanced ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: (balanced ? AppTheme.accentGreen : AppTheme.accentRed)
                                .withOpacity(0.5)),
                      ),
                      child: Text('$total/$playerCount',
                          style: AppTheme.nunitoBody(11,
                              color: balanced ? AppTheme.accentGreen : AppTheme.accentRed)),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _suggestionExpanded
                          ? PhosphorIconsFill.caretUp
                          : PhosphorIconsFill.caretDown,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            // Collapsible body
            if (_suggestionExpanded) ...[
              Divider(height: 1, color: AppTheme.outline),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: 'Đặt lại theo đề xuất mặc định',
                          icon: Icon(PhosphorIconsFill.arrowCounterClockwise,
                              size: 16, color: AppTheme.textSecondary),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _composition = Map<String, int>.from(
                                  WerewolfPresets.table[playerCount]?.roleCounts ?? const {});
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('Chưa có vai nào — bấm "Thêm vai" để dựng đội hình.',
                            style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
                      )
                    else
                      ...entries.map((e) => _buildCompRow(e.key, e.value)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _showAddRoleSheet();
                            },
                            icon: const Icon(PhosphorIconsFill.plus, size: 18),
                            label: const Text('Thêm vai'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: BorderSide(color: AppTheme.outline),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: total > 0
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    if (!balanced) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(total < playerCount
                                              ? 'Thiếu ${playerCount - total} vai — sẽ tự bù Dân Làng.'
                                              : 'Thừa ${total - playerCount} vai — sẽ tự cắt bớt.'),
                                        ),
                                      );
                                    }
                                    ref.read(setupProvider.notifier).autoDistribute(Map.from(comp));
                                  }
                                : null,
                            icon: const Icon(PhosphorIconsFill.magicWand, size: 18),
                            label: const Text('Phân vai'),
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: AppTheme.nightCard,
                              disabledForegroundColor: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompRow(String roleId, int count) {
    final role = WerewolfRoles.all.firstWhere((r) => r.id == roleId,
        orElse: () => WerewolfRoles.villager);
    final accent = AppGradients.accentForRole(roleId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(RoleIcons.forRole(role), size: 18, color: AppTheme.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(role.name, style: AppTheme.nunitoBody(13, color: accent)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(PhosphorIconsFill.minusCircle, size: 20, color: AppTheme.accentRed),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                final c = (_composition![roleId] ?? 0) - 1;
                if (c <= 0) {
                  _composition!.remove(roleId);
                } else {
                  _composition![roleId] = c;
                }
              });
            },
          ),
          SizedBox(
            width: 24,
            child: Text('$count',
                textAlign: TextAlign.center, style: AppTheme.cinzelDisplay(15)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(PhosphorIconsFill.plusCircle, size: 20, color: AppTheme.accentGreen),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _composition![roleId] = (_composition![roleId] ?? 0) + 1);
            },
          ),
        ],
      ),
    );
  }

  void _showAddRoleSheet() {
    _showRoleSearchSheet(
      title: 'Thêm vai vào đội hình',
      onPick: (role) {
        setState(() => _composition![role.id] = (_composition![role.id] ?? 0) + 1);
        Navigator.pop(context);
      },
    );
  }

  void _showRolePicker(Player player) {
    _showRoleSearchSheet(
      title: 'Chọn vai cho ${player.name}',
      onPick: (role) {
        ref.read(setupProvider.notifier).assignRole(player.id, role);
        Navigator.pop(context);
      },
    );
  }

  /// Reusable searchable role sheet. Calls [onPick] with the chosen role.
  void _showRoleSearchSheet({required String title, required void Function(Role) onPick}) {
    final roles = ref.read(setupProvider).selectedGame!.availableRoles;
    final searchCtrl = TextEditingController();
    var query = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.nightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final counts = _roleCounts;
          final filtered = query.isEmpty
              ? roles
              : roles.where((r) {
                  final q = _removeDiacritics(query.toLowerCase());
                  return _removeDiacritics(r.name.toLowerCase()).contains(q) ||
                      _removeDiacritics(r.description.toLowerCase()).contains(q);
                }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            expand: false,
            builder: (_, ctrl) => Column(
              children: [
                const SizedBox(height: 8),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(title, style: AppTheme.cinzelDisplay(16)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: false,
                    onChanged: (v) => setSheet(() => query = v.trim()),
                    style: AppTheme.nunitoBody(14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Tìm vai...',
                      hintStyle: AppTheme.nunitoBody(13, color: AppTheme.textSecondary),
                      prefixIcon: Icon(PhosphorIconsFill.magnifyingGlass, color: AppTheme.accent, size: 20),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(PhosphorIconsFill.x,
                                  size: 18, color: AppTheme.textSecondary),
                              onPressed: () {
                                searchCtrl.clear();
                                setSheet(() => query = '');
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('Không tìm thấy vai nào.',
                              style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final role = filtered[i];
                            final count = counts[role.id] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Stack(
                                children: [
                                  RoleCardWidget(
                                    role: role,
                                    compact: true,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onPick(role);
                                    },
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppGradients.accentForRole(role.id)
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppGradients.accentForRole(role.id)
                                                  .withOpacity(0.6)),
                                        ),
                                        child: Text('×$count',
                                            style: AppTheme.nunitoBody(11,
                                                color: AppGradients.accentForRole(role.id))),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _removeDiacritics(String s) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = s;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  void _startGame(BuildContext context) {
    final setup = ref.read(setupProvider);
    final game = setup.selectedGame!;
    final error = game.validateRoleSetup(setup.players);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.accentRed),
      );
      return;
    }
    final session = game.createSession(setup.players);
    ref.read(gameProvider.notifier).startGame(session);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GameMasterScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final setup = ref.watch(setupProvider);
    final players = setup.players;
    final assigned = players.where((p) => p.role != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao vai trò'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(setupProvider.notifier).clearRoles();
            },
            child: const Text('Xóa hết'),
          ),
        ],
      ),
      body: AtmosphericBackground(
        isNight: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$assigned/${players.length} đã nhận vai',
                      style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary),
                    ),
                  ),
                  if (assigned > 0) ...[
                    Icon(PhosphorIconsFill.scales, size: 14, color: _balanceColor(players)),
                    const SizedBox(width: 4),
                    Text(_balanceLabel(players),
                        style: AppTheme.nunitoBody(12, color: _balanceColor(players))),
                  ],
                ],
              ),
            ),
            _buildPresetPanel(players.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = players[i];
                  return _PlayerRoleTile(
                    player: p,
                    index: i + 1,
                    onTap: () => _showRolePicker(p),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: assigned == players.length ? () => _startGame(context) : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: AppTheme.nightCard,
                      disabledForegroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Bắt đầu Game'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRoleTile extends StatefulWidget {
  final Player player;
  final int index;
  final VoidCallback onTap;

  const _PlayerRoleTile({required this.player, required this.index, required this.onTap});

  @override
  State<_PlayerRoleTile> createState() => _PlayerRoleTileState();
}

class _PlayerRoleTileState extends State<_PlayerRoleTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  String? _prevRoleId;

  @override
  void initState() {
    super.initState();
    _prevRoleId = widget.player.role?.id;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_PlayerRoleTile old) {
    super.didUpdateWidget(old);
    if (widget.player.role?.id != _prevRoleId && widget.player.role != null) {
      _prevRoleId = widget.player.role?.id;
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.player.role;
    final accent = role != null ? AppGradients.accentForRole(role.id) : AppTheme.textSecondary;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: role != null
              ? AppTheme.glassCardGlow(glowColor: accent)
              : AppTheme.glassCard(borderColor: Colors.white12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${widget.index}', style: AppTheme.cinzelDisplay(13, color: accent)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.player.name, style: AppTheme.nunitoBody(16))),
              if (role != null) ...[
                Icon(RoleIcons.forRole(role), size: 24, color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                Text(role.name, style: AppTheme.nunitoBody(13, color: accent)),
              ] else
                Text('Chọn vai →', style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
