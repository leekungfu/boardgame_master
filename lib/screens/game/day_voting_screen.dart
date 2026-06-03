import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/role_icons.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/atmospheric_background.dart';
import '../../widgets/undo_button.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';
import '../../games/game_registry.dart';

class DayVotingScreen extends ConsumerStatefulWidget {
  const DayVotingScreen({super.key});

  @override
  ConsumerState<DayVotingScreen> createState() => _DayVotingScreenState();
}

class _DayVotingScreenState extends ConsumerState<DayVotingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _foolBannerShown = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).beginDayVote();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // rebuild palette instantly on light/dark toggle
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();
    final tally = session.currentVoteTally;
    final alivePlayers = session.alivePlayers;
    final aliveCount = alivePlayers.length;

    // Standard Werewolf rule: a player is hanged only if death-votes exceed half
    // of the living players (quá bán). Players who don't vote count as "alive" votes.
    final threshold = aliveCount ~/ 2 + 1;

    final totalDeathVotes =
        tally?.nominations.fold<int>(0, (s, e) => s + e.voteCount) ?? 0;
    final aliveVotes = (aliveCount - totalDeathVotes).clamp(0, aliveCount);

    // Find the nominee with the most death-votes. Because total death-votes can't
    // exceed the living count, at most one nominee can pass quá bán — no ties.
    String? leaderId;
    int maxVotes = 0;
    if (tally != null && tally.nominations.isNotEmpty) {
      for (final e in tally.nominations) {
        if (e.voteCount > maxVotes) {
          maxVotes = e.voteCount;
          leaderId = e.playerId;
        }
      }
    }
    final reachesMajority = maxVotes >= threshold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bỏ Phiếu'),
        actions: const [UndoButton(compact: true)],
      ),
      body: AtmosphericBackground(
        isNight: false,
        child: Column(
          children: [
            // Nomination chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đề cử (tap để thêm):', style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alivePlayers.map((p) {
                      final nominated = tally?.nominations.any((e) => e.playerId == p.id) ?? false;
                      return ActionChip(
                        avatar: Icon(RoleIcons.forRole(p.role), size: 20, color: AppTheme.textPrimary),
                        label: Text(p.name),
                        backgroundColor: nominated ? AppTheme.accent.withOpacity(0.2) : AppTheme.nightCard,
                        side: BorderSide(color: nominated ? AppTheme.accent : Colors.white24),
                        onPressed: () {
                          if (!nominated) {
                            HapticFeedback.lightImpact();
                            ref.read(gameProvider.notifier).nominatePlayer(p.id);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // Threshold info card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.3)),
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.checkSquare, size: 18, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cần ≥ $threshold phiếu chết để treo cổ (quá bán $aliveCount người sống)',
                              style: AppTheme.nunitoBody(12, color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Phiếu chết đã bỏ: $totalDeathVotes  ·  Phiếu sống (không vote): $aliveVotes',
                              style: AppTheme.nunitoBody(11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Vote cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (tally != null)
                    ...tally.nominations.map((entry) {
                      final player = session.players.firstWhere((p) => p.id == entry.playerId);
                      final isLeader = entry.playerId == leaderId && entry.voteCount >= threshold;
                      final roleAccent = AppGradients.accentForRole(player.role?.id);
                      final fraction = aliveCount > 0
                          ? (entry.voteCount / aliveCount).clamp(0.0, 1.0)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) {
                            final glow = isLeader ? AppTheme.accent.withOpacity(0.2 + 0.2 * _pulseCtrl.value) : Colors.transparent;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: AppTheme.glassCard(
                                borderColor: isLeader
                                    ? AppTheme.accent.withOpacity(0.4 + 0.4 * _pulseCtrl.value)
                                    : Colors.white12,
                              ).copyWith(boxShadow: isLeader ? [BoxShadow(color: glow, blurRadius: 16, spreadRadius: 2)] : null),
                              child: child,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(RoleIcons.forRole(player.role), size: 24, color: AppTheme.textPrimary),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(player.name, style: AppTheme.cinzelDisplay(15, color: roleAccent))),
                                  if (isLeader)
                                    Icon(PhosphorIconsFill.gavel, size: 18, color: AppTheme.accentRed),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(PhosphorIconsFill.minusCircle, size: 18),
                                    color: AppTheme.accentRed,
                                    onPressed: entry.voteCount > 0
                                        ? () {
                                            HapticFeedback.lightImpact();
                                            ref.read(gameProvider.notifier).setVoteCount(entry.playerId, entry.voteCount - 1);
                                          }
                                        : null,
                                  ),
                                  Text('${entry.voteCount}', style: AppTheme.cinzelDisplay(18)),
                                  IconButton(
                                    icon: const Icon(PhosphorIconsFill.plusCircle, size: 18),
                                    color: AppTheme.accentGreen,
                                    onPressed: totalDeathVotes < aliveCount
                                        ? () {
                                            HapticFeedback.lightImpact();
                                            ref.read(gameProvider.notifier).setVoteCount(entry.playerId, entry.voteCount + 1);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: fraction),
                                  duration: const Duration(milliseconds: 400),
                                  builder: (_, value, __) => LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isLeader ? AppTheme.accent : AppTheme.accentGreen,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text('Bỏ qua'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (tally != null && tally.nominations.isNotEmpty)
                            ? () => _confirmResult(context, leaderId, reachesMajority, threshold)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reachesMajority ? AppTheme.accentRed : null,
                          disabledBackgroundColor: AppTheme.nightCard,
                          disabledForegroundColor: AppTheme.textSecondary,
                        ),
                        child: Text(reachesMajority ? 'Treo cổ ⚖️' : 'Chốt kết quả'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResult(BuildContext context, String? leaderId, bool reachesMajority, int threshold) {
    if (reachesMajority && leaderId != null) {
      _executePlayer(context, leaderId);
    } else {
      // Không ai đạt quá bán → không treo cổ ai (phe "phiếu sống" thắng).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không ai đủ $threshold phiếu quá bán — không ai bị treo cổ hôm nay.')),
      );
      Navigator.pop(context);
    }
  }

  void _executePlayer(BuildContext context, String playerId) {
    final session = ref.read(gameProvider);
    if (session == null) return;
    final player = session.players.firstWhere((p) => p.id == playerId);
    final isFool = player.role?.id == 'fool' && !session.abilityState.foolImmunityUsed;

    if (isFool) {
      _showFoolBanner(context, () {
        ref.read(gameProvider.notifier).confirmExecution(playerId, GameRegistry.getById(session.gameId)!);
        Navigator.pop(context);
      });
      return;
    }

    HapticFeedback.heavyImpact();
    ref.read(gameProvider.notifier).confirmExecution(playerId, GameRegistry.getById(session.gameId)!);
    Navigator.pop(context);
  }

  void _showFoolBanner(BuildContext context, VoidCallback onDismiss) {
    if (_foolBannerShown) return;
    _foolBannerShown = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, val, __) => Transform.scale(
                  scale: val,
                  child: const Text('🤪', style: TextStyle(fontSize: 96)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Thằng Ngốc!', style: AppTheme.cinzelDisplay(32, color: AppTheme.foolYellow)),
              const SizedBox(height: 12),
              Text('Miễn tử lần này — họ không chết!', style: AppTheme.nunitoBody(16, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onDismiss();
      }
    });
  }
}
