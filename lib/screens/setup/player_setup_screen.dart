import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/atmospheric_background.dart';
import 'role_assignment_screen.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(setupProvider.notifier).addPlayer(name);
    final count = ref.read(setupProvider).players.length;
    _listKey.currentState?.insertItem(count - 1, duration: const Duration(milliseconds: 300));
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
    final setup = ref.watch(setupProvider);
    final game = setup.selectedGame!;
    final players = setup.players;

    return Scaffold(
      appBar: AppBar(title: Text('${game.emoji} ${game.name} · Người chơi')),
      body: AtmosphericBackground(
        isNight: true,
        child: Column(
          children: [
            // Player count badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.5), radius: 20),
                    child: Text(
                      '${players.length} người',
                      style: AppTheme.nunitoBody(13, color: AppTheme.accent),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: players.isEmpty
                  ? Center(
                      child: Text(
                        'Thêm ít nhất ${game.minPlayers} người chơi',
                        style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: players.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final list = [...players];
                        final item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                        ref.read(setupProvider.notifier).reorderPlayers(list);
                      },
                      itemBuilder: (context, i) {
                        final p = players[i];
                        return Padding(
                          key: ValueKey(p.id),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.3)),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTheme.cinzelDisplay(13, color: AppTheme.accent),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(p.name, style: AppTheme.nunitoBody(16)),
                                ),
                                IconButton(
                                  icon: Icon(PhosphorIconsFill.trash, color: AppTheme.accentRed, size: 20),
                                  onPressed: () => ref.read(setupProvider.notifier).removePlayer(p.id),
                                ),
                                Icon(PhosphorIconsFill.dotsSixVertical, color: AppTheme.textSecondary, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _buildInput(),
            _buildBottomBar(context, players.length, game.minPlayers),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.nunitoBody(16),
              decoration: InputDecoration(
                hintText: 'Tên người chơi...',
                prefixIcon: Icon(PhosphorIconsFill.userPlus, color: AppTheme.accent),
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _addPlayer, child: const Text('Thêm')),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int count, int min) {
    final ready = count >= min;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ready
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleAssignmentScreen()))
                : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: AppTheme.nightCard,
              disabledForegroundColor: AppTheme.textSecondary,
            ),
            child: Text(ready ? 'Giao vai trò →' : 'Cần thêm ${min - count} người'),
          ),
        ),
      ),
    );
  }
}
