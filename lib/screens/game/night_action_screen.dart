import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_phase.dart';
import '../../models/game_session.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../../theme/role_icons.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/atmospheric_background.dart';
import '../../widgets/ability_status_widget.dart';
import '../../widgets/undo_button.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';

class NightActionScreen extends ConsumerStatefulWidget {
  final GamePhase phase;
  final int round;

  const NightActionScreen({super.key, required this.phase, required this.round});

  @override
  ConsumerState<NightActionScreen> createState() => _NightActionScreenState();
}

class _NightActionScreenState extends ConsumerState<NightActionScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _bgFade;
  late Animation<Offset> _emojiSlide;
  late Animation<double> _emojiFade;
  late Animation<Offset> _cardSlide;

  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bgFade = CurvedAnimation(
        parent: _entranceCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn));
    _emojiSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)));
    _emojiFade = CurvedAnimation(
        parent: _entranceCtrl, curve: const Interval(0.3, 0.6, curve: Curves.easeIn));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  String get _roleId => widget.phase.activeRoleIds.isNotEmpty ? widget.phase.activeRoleIds.first : '';

  String _pickerLabel() {
    switch (_roleId) {
      case 'werewolf':
        return 'Ma Sói chọn giết:';
      case 'bodyguard':
        return 'Hiệp Sĩ bảo vệ:';
      case 'seer':
        return 'Tiên Tri kiểm tra:';
      default:
        return 'Chọn người:';
    }
  }

  void _recordAction(String playerId) {
    final notifier = ref.read(gameProvider.notifier);
    switch (_roleId) {
      case 'werewolf':
        notifier.recordWolfKill(playerId);
      case 'bodyguard':
        notifier.recordBodyguardProtect(playerId);
      case 'seer':
        notifier.recordSeer(playerId, _isSeerTargetWolf(playerId));
      default:
        break;
    }
  }

  bool _isSeerTargetWolf(String playerId) {
    final session = ref.read(gameProvider);
    if (session == null) return false;
    final player =
        session.players.firstWhere((p) => p.id == playerId, orElse: () => session.players.first);
    return player.role?.team.name == 'werewolf';
  }

  bool _isBodyguardDisabled(String playerId) {
    final session = ref.read(gameProvider);
    if (_roleId != 'bodyguard' || session == null) return false;
    return session.abilityState.lastBodyguardTarget == playerId;
  }

  void _onDone() {
    if (_roleId == 'werewolf' && _selectedPlayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Ma Sói không chọn mục tiêu — đêm nay không ai bị giết bởi Sói')),
      );
    } else if (_selectedPlayerId != null) {
      _recordAction(_selectedPlayerId!);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // rebuild palette instantly on light/dark toggle
    final session = ref.watch(gameProvider);
    if (session == null) return const SizedBox.shrink();

    final roleAccent = AppGradients.accentForRole(_roleId);
    final alivePlayers = session.alivePlayers;
    final isWitch = _roleId == 'witch';
    final isNightStart = widget.phase.activeRoleIds.isEmpty;

    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: AtmosphericBackground(
          isNight: true,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(PhosphorIconsFill.caretLeft, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      Text('Đêm ${widget.round}',
                          style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
                      const UndoButton(compact: true),
                    ],
                  ),
                ),
                SlideTransition(
                  position: _emojiSlide,
                  child: FadeTransition(
                    opacity: _emojiFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _roleEmoji(),
                        style: TextStyle(
                          fontSize: 64,
                          shadows: [Shadow(color: roleAccent.withOpacity(0.8), blurRadius: 20)],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (widget.phase.scriptText.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: AppTheme.glassCardGlow(glowColor: roleAccent),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.phase.name,
                                      style: AppTheme.cinzelDisplay(16, color: roleAccent)),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.phase.scriptText,
                                    style: AppTheme.nunitoBody(15)
                                        .copyWith(fontStyle: FontStyle.italic, height: 1.7),
                                  ),
                                ],
                              ),
                            ),
                          if (isWitch) ...[
                            AbilityStatusWidget(abilityState: session.abilityState),
                            const SizedBox(height: 16),
                          ],
                          if (!isNightStart && _roleId.isNotEmpty && !isWitch) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(_pickerLabel(),
                                  style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                            ),
                            const SizedBox(height: 10),
                            ...alivePlayers.map((p) => _buildPlayerRow(p, roleAccent)),
                          ],
                          if (isWitch) _buildWitchActions(session, alivePlayers),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _onDone();
        },
        backgroundColor: roleAccent,
        foregroundColor: Colors.black,
        icon: const Icon(PhosphorIconsFill.checkCircle),
        label: Text(
          _selectedPlayerId != null ? 'Xác nhận' : 'Bỏ qua',
          style: AppTheme.nunitoBody(15, color: Colors.black).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _roleEmoji() {
    switch (_roleId) {
      case 'werewolf':
        return '🐺';
      case 'seer':
        return '🔮';
      case 'witch':
        return '🧪';
      case 'bodyguard':
        return '🛡️';
      default:
        return '🌙';
    }
  }

  Widget _buildPlayerRow(Player p, Color accent) {
    final isSelected = _selectedPlayerId == p.id;
    final isDisabled = _isBodyguardDisabled(p.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                setState(() => _selectedPlayerId = isSelected ? null : p.id);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: isSelected
              ? AppTheme.glassCardGlow(glowColor: accent)
              : AppTheme.glassCard(borderColor: isDisabled ? Colors.white12 : Colors.white24),
          child: Row(
            children: [
              Icon(RoleIcons.forRole(p.role), size: 22, color: AppTheme.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(p.name,
                      style: AppTheme.nunitoBody(15,
                          color: isDisabled ? AppTheme.textSecondary : AppTheme.textPrimary))),
              if (isDisabled)
                Icon(PhosphorIconsFill.lock, color: AppTheme.textSecondary, size: 16),
              if (isSelected) Icon(PhosphorIconsFill.checkCircle, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWitchActions(GameSession session, List<Player> alivePlayers) {
    final abilityState = session.abilityState;
    final wolfTargetId = session.currentNightWolfTarget;
    final wolfVictim = wolfTargetId != null
        ? session.players.firstWhere((p) => p.id == wolfTargetId,
            orElse: () => session.players.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wolfVictim != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration:
                AppTheme.glassCard(borderColor: AppTheme.accentRed.withOpacity(0.5)),
            child: Row(
              children: [
                const Text('🐺', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Ma Sói đã chọn: ',
                    style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                Text(wolfVictim.name,
                    style: AppTheme.nunitoBody(14, color: AppTheme.accentRed)),
              ],
            ),
          ),
          if (!abilityState.witchSaveUsed) ...[
            Text('Dùng bình cứu cho ${wolfVictim.name}?',
                style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(gameProvider.notifier).recordWitchSave(wolfVictim.id);
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentGreen,
                  side: BorderSide(color: AppTheme.accentGreen),
                ),
                child: const Text('Cứu người này'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppTheme.glassCard(borderColor: Colors.white12),
            child: Text('Ma Sói chưa chọn mục tiêu đêm nay.',
                style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
          ),
        ],
        if (!abilityState.witchKillUsed) ...[
          Text('Dùng bình độc (chọn mục tiêu):',
              style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...alivePlayers.map((p) {
            final isSelected = _selectedPlayerId == p.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isSelected) {
                    setState(() => _selectedPlayerId = null);
                    ref.read(gameProvider.notifier).clearWitchKill();
                  } else {
                    setState(() => _selectedPlayerId = p.id);
                    ref.read(gameProvider.notifier).recordWitchKill(p.id);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: isSelected
                      ? AppTheme.glassCardGlow(glowColor: AppTheme.accentRed)
                      : AppTheme.glassCard(borderColor: Colors.white24),
                  child: Row(
                    children: [
                      Icon(RoleIcons.forRole(p.role), size: 20, color: AppTheme.textPrimary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.name, style: AppTheme.nunitoBody(15))),
                      if (isSelected)
                        Icon(PhosphorIconsFill.checkCircle, color: AppTheme.accentRed, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
