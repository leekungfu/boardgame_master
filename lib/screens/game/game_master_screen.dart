import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/role_icons.dart';
import '../../theme/app_gradients.dart';
import '../../models/game_session.dart';
import '../../models/game_phase.dart';
import '../../models/night_action_record.dart';
import '../../models/player.dart';
import '../../models/role.dart';
import '../../games/game_registry.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/atmospheric_background.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/undo_button.dart';
import 'night_action_screen.dart';
import 'day_voting_screen.dart';
import 'role_reference_panel.dart';
import 'rules_panel.dart';

enum _SortMode { defaultOrder, byRole }
enum _FilterMode { all, aliveOnly, deadOnly }

int _rolePriority(String? roleId) {
  switch (roleId) {
    case 'werewolf': return 1;
    case 'bodyguard': return 2;
    case 'seer': return 3;
    case 'witch': return 4;
    case 'hunter': return 5;
    case 'fool': return 6;
    case 'villager': return 7;
    default: return 8;
  }
}

class GameMasterScreen extends ConsumerStatefulWidget {
  const GameMasterScreen({super.key});

  @override
  ConsumerState<GameMasterScreen> createState() => _GameMasterScreenState();
}

class _GameMasterScreenState extends ConsumerState<GameMasterScreen>
    with TickerProviderStateMixin {
  bool _showNotes = false;
  bool _showRoles = false;
  final _noteController = TextEditingController();

  _SortMode _sortMode = _SortMode.defaultOrder;
  _FilterMode _filterMode = _FilterMode.all;

  // Win screen animations
  late ConfettiController _confettiCtrl;
  late AnimationController _wolfPulseCtrl;
  late Animation<double> _wolfScale;

  // Phase transition animation
  late AnimationController _transitionCtrl;
  late Animation<double> _phaseFade;
  late Animation<Offset> _phaseSlide;

  // Push-loop guards
  String? _lastPhaseId;
  String? _lastPushedPhaseId;
  String? _morningResolvedPhaseId;

  // Show the rules sheet once at the start of the game.
  bool _rulesShown = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _wolfPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _wolfScale = Tween<double>(begin: 0.5, end: 1.2)
        .animate(CurvedAnimation(parent: _wolfPulseCtrl, curve: Curves.elasticOut));

    _transitionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _phaseFade = CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeIn);
    _phaseSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOut));
    _transitionCtrl.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _confettiCtrl.dispose();
    _wolfPulseCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }

  List<Player> _filteredSortedPlayers(List<Player> all) {
    List<Player> filtered;
    switch (_filterMode) {
      case _FilterMode.aliveOnly:
        filtered = all.where((p) => p.isAlive).toList();
      case _FilterMode.deadOnly:
        filtered = all.where((p) => !p.isAlive).toList();
      case _FilterMode.all:
        filtered = List.from(all);
    }
    if (_sortMode == _SortMode.byRole) {
      filtered.sort((a, b) => _rolePriority(a.role?.id).compareTo(_rolePriority(b.role?.id)));
    }
    return filtered;
  }

  void _onPhaseChanged(String phaseId, GameSession session) {
    if (phaseId == _lastPhaseId) return;
    _lastPhaseId = phaseId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _transitionCtrl.forward(from: 0);
    });

    final phase = session.currentPhase;
    final game = GameRegistry.getById(session.gameId);

    // Night action step — push once per unique phase
    if (phase.phaseType == PhaseType.nightStep &&
        phase.activeRoleIds.isNotEmpty &&
        phaseId != _lastPushedPhaseId) {
      _lastPushedPhaseId = phaseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(gameProvider.notifier).beginNightAction(session.round);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => NightActionScreen(phase: phase, round: session.round),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => ref.read(gameProvider.notifier).nextPhase());
      });
    }

    // Morning — resolve night deaths once per morning phase
    if (phase.phaseType == PhaseType.morning && phaseId != _morningResolvedPhaseId) {
      _morningResolvedPhaseId = phaseId;
      if (game != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(gameProvider.notifier).resolveNight(game);
        });
      }
    }

    // Day voting — push once per unique phase
    if (phase.phaseType == PhaseType.dayVoting && phaseId != _lastPushedPhaseId) {
      _lastPushedPhaseId = phaseId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DayVotingScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ).then((_) => ref.read(gameProvider.notifier).nextPhase());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // rebuild palette instantly on light/dark toggle
    final session = ref.watch(gameProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('Không có game đang chạy')));
    }

    if (session.abilityState.hunterShotPending && !session.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHunterDialog(context, session));
    }

    // Show the rules sheet once when the game first opens.
    if (!_rulesShown) {
      _rulesShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GameRulesSheet.show(context, atGameStart: true);
      });
    }

    if (session.isGameOver) return _buildResultScreen(context, session);

    final phase = session.currentPhase;
    final isNight = phase.isNight;

    _onPhaseChanged(phase.id, session);

    final displayPlayers = _filteredSortedPlayers(session.players);

    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: isNight ? AppTheme.dayBg : AppTheme.night,
              end: isNight ? AppTheme.night : AppTheme.dayBg,
            ),
            duration: const Duration(milliseconds: 800),
            builder: (_, color, __) => Container(
              color: color ?? (isNight ? AppTheme.night : AppTheme.dayBg),
            ),
          ),
          AtmosphericBackground(isNight: isNight, child: const SizedBox.shrink()),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, session, isNight),
                _PhaseProgressBar(session: session),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _phaseFade,
                      child: SlideTransition(
                        position: _phaseSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhaseCard(phase, isNight),
                            const SizedBox(height: 20),
                            if (phase.durationSeconds > 0) ...[
                              Center(
                                child: CountdownTimer(
                                  key: ValueKey(phase.id),
                                  seconds: phase.durationSeconds,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (phase.phaseType == PhaseType.morning)
                              _MorningAnnouncement(session: session),
                            if (_showRoles) ...[
                              _PlayerListPanel(players: displayPlayers, session: session),
                              const SizedBox(height: 20),
                            ],
                            if (_showNotes) ...[
                              _NotesPanel(controller: _noteController, session: session),
                              const SizedBox(height: 20),
                            ],
                            _buildSortFilterRow(),
                            const SizedBox(height: 12),
                            _AlivePlayerChips(players: displayPlayers, session: session),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _PhaseNavigator(session: session, onHome: () => _confirmEndGame(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilterRow() {
    return Row(
      children: [
        // Sort toggle
        GestureDetector(
          onTap: () => setState(() {
            _sortMode = _sortMode == _SortMode.defaultOrder ? _SortMode.byRole : _SortMode.defaultOrder;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: AppTheme.glassCard(
              borderColor: _sortMode == _SortMode.byRole ? AppTheme.accent : Colors.white24,
              radius: 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsFill.sortAscending, size: 14,
                    color: _sortMode == _SortMode.byRole ? AppTheme.accent : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _sortMode == _SortMode.byRole ? 'Theo vai' : 'Mặc định',
                  style: AppTheme.nunitoBody(12,
                      color: _sortMode == _SortMode.byRole ? AppTheme.accent : AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter toggle cycling through all/alive/dead
        GestureDetector(
          onTap: () => setState(() {
            _filterMode = switch (_filterMode) {
              _FilterMode.all => _FilterMode.aliveOnly,
              _FilterMode.aliveOnly => _FilterMode.deadOnly,
              _FilterMode.deadOnly => _FilterMode.all,
            };
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: AppTheme.glassCard(
              borderColor: _filterMode != _FilterMode.all ? AppTheme.accent : Colors.white24,
              radius: 20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsFill.funnel, size: 14,
                    color: _filterMode != _FilterMode.all ? AppTheme.accent : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  switch (_filterMode) {
                    _FilterMode.all => 'Tất cả',
                    _FilterMode.aliveOnly => 'Sống',
                    _FilterMode.deadOnly => 'Chết',
                  },
                  style: AppTheme.nunitoBody(12,
                      color: _filterMode != _FilterMode.all ? AppTheme.accent : AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, GameSession session, bool isNight) {
    const density = VisualDensity.compact;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(
              'Vòng ${session.round} · ${isNight ? "Đêm" : "Ngày"}',
              style: AppTheme.cinzelDisplay(16),
            ),
            const Spacer(),
            // Icon group — packed together at the right edge.
            const UndoButton(compact: true, visualDensity: density),
            IconButton(
              visualDensity: density,
              icon: Icon(PhosphorIconsFill.bookOpen, color: AppTheme.textSecondary, size: 21),
              tooltip: 'Tra cứu vai',
              onPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const RoleReferencePanel(),
                );
              },
            ),
            IconButton(
              visualDensity: density,
              icon: Icon(
                _showRoles ? PhosphorIconsFill.eyeSlash : PhosphorIconsFill.users,
                color: AppTheme.textSecondary,
                size: 21,
              ),
              tooltip: 'Hiện/ẩn vai',
              onPressed: () => setState(() => _showRoles = !_showRoles),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              // Open below the button, anchored to its left edge.
              position: PopupMenuPosition.under,
              icon: Icon(PhosphorIconsFill.dotsThreeVertical,
                  color: AppTheme.textSecondary, size: 21),
              tooltip: 'Thêm',
              onSelected: (v) {
                HapticFeedback.lightImpact();
                switch (v) {
                  case 'rules':
                    GameRulesSheet.show(context);
                  case 'log':
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _GameLogPanel(session: session),
                    );
                  case 'notes':
                    setState(() => _showNotes = !_showNotes);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rules',
                  child: ListTile(
                      leading: Icon(PhosphorIconsFill.question), title: Text('Luật chơi')),
                ),
                const PopupMenuItem(
                  value: 'log',
                  child: ListTile(
                      leading: Icon(PhosphorIconsFill.clockCounterClockwise),
                      title: Text('Nhật ký game')),
                ),
                PopupMenuItem(
                  value: 'notes',
                  child: ListTile(
                    leading: Icon(
                        _showNotes ? PhosphorIconsFill.note : PhosphorIconsFill.notePencil),
                    title: const Text('Ghi chú'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(GamePhase phase, bool isNight) {
    final roleId = phase.activeRoleIds.isNotEmpty ? phase.activeRoleIds.first : null;
    final accent = roleId != null ? AppGradients.accentForRole(roleId) : AppTheme.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardGlow(glowColor: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phase.name, style: AppTheme.cinzelDisplay(20, color: accent)),
          const SizedBox(height: 10),
          Text(phase.description, style: AppTheme.nunitoBody(15).copyWith(height: 1.6)),
        ],
      ),
    );
  }

  void _showHunterDialog(BuildContext context, GameSession session) {
    if (!session.abilityState.hunterShotPending) return;
    final game = GameRegistry.getById(session.gameId);
    if (game == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.nightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.hunterAmber.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: AppTheme.hunterAmber.withOpacity(0.2), blurRadius: 20)],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏹',
                  style: TextStyle(
                      fontSize: 64,
                      shadows: [Shadow(color: AppTheme.hunterAmber.withOpacity(0.8), blurRadius: 20)])),
              const SizedBox(height: 12),
              Text('Thợ Săn vừa chết!',
                  style: AppTheme.cinzelDisplay(22, color: AppTheme.hunterAmber)),
              const SizedBox(height: 8),
              Text('Họ được bắn chết 1 người trước khi ra đi.',
                  style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ...session.alivePlayers.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(context);
                        ref.read(gameProvider.notifier).recordHunterShot(p.id, game);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration:
                            AppTheme.glassCard(borderColor: AppTheme.hunterAmber.withOpacity(0.3)),
                        child: Row(
                          children: [
                            Icon(RoleIcons.forRole(p.role), size: 22, color: AppTheme.textPrimary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.name, style: AppTheme.nunitoBody(15))),
                            Icon(PhosphorIconsFill.caretRight, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, GameSession session) {
    final isVillagerWin = session.result == GameResult.villagerWin;
    if (isVillagerWin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiCtrl.play());
    }

    return Scaffold(
      body: Stack(
        children: [
          AtmosphericBackground(isNight: !isVillagerWin, child: const SizedBox.shrink()),
          if (!isVillagerWin)
            AnimatedBuilder(
              animation: _wolfPulseCtrl,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.wolfCrimson.withOpacity(0.15 + 0.1 * _wolfPulseCtrl.value),
                      Colors.transparent,
                    ],
                    radius: 1.0,
                  ),
                ),
              ),
            ),
          if (isVillagerWin)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirectionality: BlastDirectionality.explosive,
                colors: [AppTheme.accent, Colors.white, AppTheme.accentGreen, AppTheme.seerViolet],
                numberOfParticles: 30,
                maxBlastForce: 20,
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // ── Win header ──────────────────────────────────────────────
                  if (isVillagerWin)
                    const Text('🎉', style: TextStyle(fontSize: 80))
                  else
                    ScaleTransition(
                      scale: _wolfScale,
                      child: const Text('🐺', style: TextStyle(fontSize: 80)),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    isVillagerWin ? 'Dân Làng Chiến Thắng!' : 'Ma Sói Chiến Thắng!',
                    style: AppTheme.cinzelDisplay(26,
                        color: isVillagerWin ? AppTheme.accent : AppTheme.wolfCrimson),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vòng ${session.round} · ${session.players.where((p) => p.isAlive).length}/${session.players.length} còn sống',
                    style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  // ── Final role reveal ───────────────────────────────────────
                  _buildFinalRoleReveal(context, session),
                  const SizedBox(height: 24),
                  // ── Game log recap ──────────────────────────────────────────
                  _GameLogInline(session: session),
                  const SizedBox(height: 32),
                  // ── Home button ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(gameProvider.notifier).endGame();
                        ref.read(setupProvider.notifier).reset();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Về trang chủ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalRoleReveal(BuildContext context, GameSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kết quả vai trò:', style: AppTheme.cinzelDisplay(16)),
          const SizedBox(height: 12),
          ...session.players.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(RoleIcons.forRole(p.role), size: 20, color: AppTheme.textPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: AppTheme
                            .nunitoBody(15,
                                color: p.isAlive ? AppTheme.textPrimary : AppTheme.textSecondary)
                            .copyWith(decoration: p.isAlive ? null : TextDecoration.lineThrough),
                      ),
                    ),
                    Text(
                      p.role?.name ?? '',
                      style: AppTheme.nunitoBody(12,
                          color: p.role?.team == RoleTeam.werewolf
                              ? AppTheme.wolfCrimson
                              : AppTheme.accent),
                    ),
                    if (!p.isAlive) const Text(' 💀', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _confirmEndGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.nightCard,
        title: Text('Kết thúc game?', style: AppTheme.cinzelDisplay(18)),
        content: Text('Tiến trình game sẽ bị mất.', style: AppTheme.nunitoBody(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).endGame();
              ref.read(setupProvider.notifier).reset();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text('Kết thúc', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PhaseProgressBar extends StatelessWidget {
  final GameSession session;
  const _PhaseProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final total = session.phases.length;
    final current = session.currentPhaseIndex + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: current / total),
            duration: const Duration(milliseconds: 400),
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text('Giai đoạn $current / $total',
              style: AppTheme.nunitoBody(11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _MorningAnnouncement extends StatelessWidget {
  final GameSession session;
  const _MorningAnnouncement({required this.session});

  String? _nameOf(String? id) {
    if (id == null) return null;
    final p = session.players.where((p) => p.id == id);
    return p.isEmpty ? null : p.first.name;
  }

  @override
  Widget build(BuildContext context) {
    if (session.nightLog.isEmpty) return const SizedBox.shrink();
    final lastNight = session.nightLog.last;
    if (!lastNight.resolved) return const SizedBox.shrink();
    final died = lastNight.resolveDeaths();
    final hasDeath = died.isNotEmpty;

    return Column(
      children: [
        // ── Public announcement (read aloud) ────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: hasDeath
                ? AppTheme.danger.withOpacity(0.15)
                : AppTheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: hasDeath
                    ? AppTheme.accentRed.withOpacity(0.4)
                    : AppTheme.accentGreen.withOpacity(0.4)),
          ),
          child: hasDeath
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('☀️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('Bình minh',
                            style: AppTheme.cinzelDisplay(16, color: AppTheme.accentRed)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...died.map((id) {
                      final player = session.players
                          .firstWhere((p) => p.id == id, orElse: () => session.players.first);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(RoleIcons.forRole(player.role), size: 22, color: AppTheme.textPrimary),
                            const SizedBox(width: 8),
                            Text(player.name,
                                style: AppTheme.cinzelDisplay(15, color: AppTheme.accent)
                                    .copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(width: 8),
                            const Text('💀', style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text(player.role?.name ?? '',
                                style: AppTheme.nunitoBody(12, color: AppTheme.accentRed)),
                          ],
                        ),
                      );
                    }),
                  ],
                )
              : Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text('Đêm bình yên — không ai chết.',
                        style: AppTheme.nunitoBody(15, color: AppTheme.accentGreen)),
                  ],
                ),
        ),
        // ── Private QT night recap ──────────────────────────────────────────
        _buildNightRecap(lastNight),
      ],
    );
  }

  Widget _buildNightRecap(NightActionRecord lastNight) {
    final rows = <Widget>[];

    final wolfTarget = _nameOf(lastNight.wolfTarget);
    if (wolfTarget != null) {
      rows.add(_recapRow('🐺', 'Ma Sói', 'cắn $wolfTarget', AppTheme.wolfCrimson));
    } else {
      rows.add(_recapRow('🐺', 'Ma Sói', 'không cắn ai', AppTheme.textSecondary));
    }

    final bgTarget = _nameOf(lastNight.bodyguardTarget);
    if (bgTarget != null) {
      rows.add(_recapRow('🛡️', 'Hiệp Sĩ', 'bảo vệ $bgTarget', AppTheme.accentGreen));
    }

    final seerTarget = _nameOf(lastNight.seerTarget);
    if (seerTarget != null) {
      final result = lastNight.seerResultIsWolf == true ? 'là SÓI' : 'là DÂN';
      rows.add(_recapRow('🔮', 'Tiên Tri', 'soi $seerTarget → $result', AppTheme.seerViolet));
    }

    final saveTarget = _nameOf(lastNight.witchSaveTarget);
    if (saveTarget != null) {
      rows.add(_recapRow('🧪', 'Phù Thủy', 'cứu $saveTarget', AppTheme.accentGreen));
    }
    final killTarget = _nameOf(lastNight.witchKillTarget);
    if (killTarget != null) {
      rows.add(_recapRow('🧪', 'Phù Thủy', 'dùng độc giết $killTarget', AppTheme.accentRed));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.moonStars, size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text('Tóm tắt đêm qua (chỉ QT thấy)',
                  style: AppTheme.nunitoBody(12, color: AppTheme.accent)),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _recapRow(String emoji, String role, String action, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('$role: ', style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(action,
                style: AppTheme.nunitoBody(13, color: color).copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PlayerListPanel extends ConsumerWidget {
  final List<Player> players;
  final GameSession session;
  const _PlayerListPanel({required this.players, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Người chơi (chỉ QT thấy)', style: AppTheme.cinzelDisplay(15)),
          ),
          const Divider(height: 1, color: Colors.white12),
          ...players.map((p) => _PlayerRow(player: p, session: session)),
        ],
      ),
    );
  }
}

class _PlayerRow extends ConsumerWidget {
  final Player player;
  final GameSession session;
  const _PlayerRow({required this.player, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppGradients.accentForRole(player.role?.id);
    return ListTile(
      dense: true,
      leading: Icon(RoleIcons.forRole(player.role), size: 22, color: AppTheme.textPrimary),
      title: Text(
        player.name,
        style: AppTheme
            .nunitoBody(15,
                color: player.isAlive ? AppTheme.textPrimary : AppTheme.textSecondary)
            .copyWith(decoration: player.isAlive ? null : TextDecoration.lineThrough),
      ),
      subtitle: Text(player.role?.name ?? 'Chưa giao vai',
          style: AppTheme.nunitoBody(11, color: accent)),
      trailing: player.isAlive
          ? IconButton(
              icon: Icon(PhosphorIconsFill.x, color: AppTheme.accentRed, size: 18),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(gameProvider.notifier).killPlayer(player.id);
              },
            )
          : IconButton(
              icon: Icon(PhosphorIconsFill.heart, color: AppTheme.accentGreen, size: 18),
              onPressed: () => ref.read(gameProvider.notifier).revivePlayer(player.id),
            ),
    );
  }
}

class _NotesPanel extends ConsumerWidget {
  final TextEditingController controller;
  final GameSession session;
  const _NotesPanel({required this.controller, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (controller.text.isEmpty && session.qtNote != null) controller.text = session.qtNote!;
    return TextField(
      controller: controller,
      maxLines: 4,
      onChanged: (v) => ref.read(gameProvider.notifier).updateNote(v),
      decoration: InputDecoration(
        hintText: 'Ghi chú riêng của QT (ẩn với người chơi)...',
        prefixIcon: Icon(PhosphorIconsFill.note, color: AppTheme.accent),
      ),
    );
  }
}

class _AlivePlayerChips extends ConsumerWidget {
  final List<Player> players;
  final GameSession session;
  const _AlivePlayerChips({required this.players, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alive = players.where((p) => p.isAlive).toList();
    final dead = players.where((p) => !p.isAlive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Còn sống (${alive.length})', style: AppTheme.cinzelDisplay(15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: alive.map((p) {
            final accent = AppGradients.accentForRole(p.role?.id);
            return ActionChip(
              avatar: Icon(RoleIcons.forRole(p.role), size: 20, color: AppTheme.textPrimary),
              label: Text(p.name),
              side: BorderSide(color: accent.withOpacity(0.5)),
              backgroundColor: accent.withOpacity(0.08),
              onPressed: () => _confirmKill(context, ref, p),
            );
          }).toList(),
        ),
        if (dead.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Đã chết (${dead.length})',
              style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dead
                .map((p) => Chip(
                      avatar: Icon(RoleIcons.forRole(p.role), size: 20, color: AppTheme.textPrimary),
                      label: Text(p.name,
                          style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)
                              .copyWith(decoration: TextDecoration.lineThrough)),
                      backgroundColor: Colors.black26,
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  void _confirmKill(BuildContext context, WidgetRef ref, Player p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.nightCard,
        title: Text('Đánh dấu ${p.name} đã chết?', style: AppTheme.cinzelDisplay(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              ref.read(gameProvider.notifier).killPlayer(p.id);
            },
            child: Text('Xác nhận', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}

class _PhaseNavigator extends ConsumerWidget {
  final GameSession session;
  final VoidCallback onHome;
  const _PhaseNavigator({required this.session, required this.onHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLastPhase = !session.hasNextPhase;
    final game = GameRegistry.getById(session.gameId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: previous-phase (or empty to keep Home centred).
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: session.currentPhaseIndex > 0
                    ? OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(gameProvider.notifier).prevPhase();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.accent),
                          foregroundColor: AppTheme.accent,
                        ),
                        child: const Text('← Trước'),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Center: Home / end-game — filled yellow accent for emphasis.
            Material(
              color: AppTheme.highlight,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onHome,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(PhosphorIconsFill.house, color: AppTheme.onAccent, size: 24),
                ),
              ),
            ),
            // Right: next phase / next round (primary action).
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (isLastPhase && game != null) {
                      ref.read(gameProvider.notifier).nextRound(game);
                    } else {
                      ref.read(gameProvider.notifier).nextPhase();
                    }
                  },
                  child: const Text('Tiếp →'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline game log embedded in the result screen (no sheet chrome).
class _GameLogInline extends StatelessWidget {
  final GameSession session;
  const _GameLogInline({required this.session});

  String _nameOf(String? id) {
    if (id == null) return '?';
    final p = session.players.where((p) => p.id == id);
    return p.isEmpty ? '?' : p.first.name;
  }

  Widget _event(String emoji, String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTheme.nunitoBody(13, color: color))),
          ],
        ),
      );

  Widget _buildRoundBlock(int round) {
    final night = session.nightLog.where((n) => n.round == round).toList();
    final nightRec = night.isEmpty ? null : night.first;
    final executions = session.deathHistory
        .where((d) => d.round == round && d.cause == DeathCause.execution)
        .toList();
    final hunterShots = session.deathHistory
        .where((d) => d.round == round && d.cause == DeathCause.hunterShot)
        .toList();
    final manualKills = session.deathHistory
        .where((d) => d.round == round && d.cause == DeathCause.manualKill)
        .toList();

    final nightEvents = <Widget>[];
    if (nightRec != null) {
      if (nightRec.bodyguardTarget != null)
        nightEvents.add(_event('🛡️', 'Hiệp Sĩ bảo vệ ${_nameOf(nightRec.bodyguardTarget)}', AppTheme.accentGreen));
      if (nightRec.wolfTarget != null)
        nightEvents.add(_event('🐺', 'Ma Sói cắn ${_nameOf(nightRec.wolfTarget)}', AppTheme.wolfCrimson));
      else
        nightEvents.add(_event('🐺', 'Ma Sói không cắn ai', AppTheme.textSecondary));
      if (nightRec.seerTarget != null)
        nightEvents.add(_event('🔮', 'Tiên Tri soi ${_nameOf(nightRec.seerTarget)} → ${nightRec.seerResultIsWolf == true ? "là SÓI" : "là DÂN"}', AppTheme.accent));
      if (nightRec.witchSaveTarget != null)
        nightEvents.add(_event('🧪', 'Phù Thủy cứu ${_nameOf(nightRec.witchSaveTarget)}', AppTheme.accentGreen));
      if (nightRec.witchKillTarget != null)
        nightEvents.add(_event('🧪', 'Phù Thủy dùng độc giết ${_nameOf(nightRec.witchKillTarget)}', AppTheme.accentRed));
      final died = nightRec.resolveDeaths();
      if (died.isEmpty)
        nightEvents.add(_event('🌅', 'Sáng ra: không ai chết', AppTheme.accentGreen));
      else
        for (final id in died)
          nightEvents.add(_event('💀', 'Sáng ra: ${_nameOf(id)} đã chết', AppTheme.accentRed));
    }

    final dayEvents = <Widget>[
      for (final d in executions) _event('⚖️', 'Làng xử tử ${_nameOf(d.playerId)}', AppTheme.accentRed),
      for (final d in hunterShots) _event('🏹', 'Thợ Săn bắn chết ${_nameOf(d.playerId)}', AppTheme.hunterAmber),
      for (final d in manualKills) _event('✋', 'QT đánh dấu ${_nameOf(d.playerId)} chết', AppTheme.textSecondary),
    ];

    if (nightEvents.isEmpty && dayEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vòng $round', style: AppTheme.cinzelDisplay(14, color: AppTheme.accent)),
          const SizedBox(height: 8),
          if (nightEvents.isNotEmpty) ...[
            Text('🌙 Đêm', style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            ...nightEvents,
          ],
          if (dayEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('☀️ Ngày', style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            ...dayEvents,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (session.nightLog.isEmpty && session.deathHistory.isEmpty) return const SizedBox.shrink();
    final rounds = [for (var r = 1; r <= session.round; r++) r];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsFill.clockCounterClockwise, color: AppTheme.accent, size: 18),
            const SizedBox(width: 8),
            Text('Nhật ký ván chơi', style: AppTheme.cinzelDisplay(16)),
          ],
        ),
        const SizedBox(height: 12),
        ...rounds.map((r) => _buildRoundBlock(r)),
      ],
    );
  }
}

/// Full chronological game log — all nights and day executions, grouped by round.
class _GameLogPanel extends StatelessWidget {
  final GameSession session;
  const _GameLogPanel({required this.session});

  String _nameOf(String? id) {
    if (id == null) return '?';
    final p = session.players.where((p) => p.id == id);
    return p.isEmpty ? '?' : p.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final maxRound = session.round;
    final rounds = [for (var r = 1; r <= maxRound; r++) r];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.nightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.clockCounterClockwise, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Nhật ký toàn bộ ván', style: AppTheme.cinzelDisplay(17)),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  if (session.nightLog.isEmpty && session.deathHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Chưa có sự kiện nào.',
                            style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ...rounds.map((r) => _buildRoundBlock(r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundBlock(int round) {
    final night = session.nightLog.where((n) => n.round == round).toList();
    final nightRec = night.isEmpty ? null : night.first;
    final executions =
        session.deathHistory.where((d) => d.round == round && d.cause == DeathCause.execution).toList();
    final hunterShots =
        session.deathHistory.where((d) => d.round == round && d.cause == DeathCause.hunterShot).toList();
    final manualKills =
        session.deathHistory.where((d) => d.round == round && d.cause == DeathCause.manualKill).toList();

    final nightEvents = <Widget>[];
    if (nightRec != null) {
      if (nightRec.bodyguardTarget != null) {
        nightEvents.add(_event('🛡️', 'Hiệp Sĩ bảo vệ ${_nameOf(nightRec.bodyguardTarget)}',
            AppTheme.accentGreen));
      }
      if (nightRec.wolfTarget != null) {
        nightEvents.add(
            _event('🐺', 'Ma Sói cắn ${_nameOf(nightRec.wolfTarget)}', AppTheme.wolfCrimson));
      } else {
        nightEvents.add(_event('🐺', 'Ma Sói không cắn ai', AppTheme.textSecondary));
      }
      if (nightRec.seerTarget != null) {
        final res = nightRec.seerResultIsWolf == true ? 'là SÓI' : 'là DÂN';
        nightEvents.add(_event(
            '🔮', 'Tiên Tri soi ${_nameOf(nightRec.seerTarget)} → $res', AppTheme.seerViolet));
      }
      if (nightRec.witchSaveTarget != null) {
        nightEvents.add(_event(
            '🧪', 'Phù Thủy cứu ${_nameOf(nightRec.witchSaveTarget)}', AppTheme.accentGreen));
      }
      if (nightRec.witchKillTarget != null) {
        nightEvents.add(_event('🧪', 'Phù Thủy dùng độc giết ${_nameOf(nightRec.witchKillTarget)}',
            AppTheme.accentRed));
      }
      final died = nightRec.resolveDeaths();
      if (died.isEmpty) {
        nightEvents.add(_event('🌅', 'Sáng ra: không ai chết', AppTheme.accentGreen));
      } else {
        for (final id in died) {
          nightEvents.add(_event('💀', 'Sáng ra: ${_nameOf(id)} đã chết', AppTheme.accentRed));
        }
      }
    }

    final dayEvents = <Widget>[
      for (final d in executions)
        _event('⚖️', 'Làng xử tử ${_nameOf(d.playerId)}', AppTheme.accentRed),
      for (final d in hunterShots)
        _event('🏹', 'Thợ Săn bắn chết ${_nameOf(d.playerId)}', AppTheme.hunterAmber),
      for (final d in manualKills)
        _event('✋', 'QT đánh dấu ${_nameOf(d.playerId)} chết', AppTheme.textSecondary),
    ];

    if (nightEvents.isEmpty && dayEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vòng $round', style: AppTheme.cinzelDisplay(15, color: AppTheme.accent)),
          const SizedBox(height: 8),
          if (nightEvents.isNotEmpty) ...[
            Text('🌙 Đêm', style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            ...nightEvents,
          ],
          if (dayEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('☀️ Ngày', style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            ...dayEvents,
          ],
        ],
      ),
    );
  }

  Widget _event(String emoji, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTheme.nunitoBody(13, color: color)),
          ),
        ],
      ),
    );
  }
}
