import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/role_icons.dart';
import '../../models/role.dart';
import '../../providers/game_provider.dart';
import '../../games/werewolf/role_glossary.dart';

/// Role glossary panel — shows the full standardized role list (display-only),
/// grouped by team, with search. Roles actually in the current game are pulled
/// to the top and highlighted.
class RoleReferencePanel extends ConsumerStatefulWidget {
  const RoleReferencePanel({super.key});

  @override
  ConsumerState<RoleReferencePanel> createState() => _RoleReferencePanelState();
}

class _RoleReferencePanelState extends ConsumerState<RoleReferencePanel> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(GlossaryRole r) {
    if (_query.isEmpty) return true;
    final q = _removeDiacritics(_query.toLowerCase());
    return _removeDiacritics(r.nameVi.toLowerCase()).contains(q) ||
        _removeDiacritics(r.nameEn.toLowerCase()).contains(q) ||
        _removeDiacritics(r.description.toLowerCase()).contains(q);
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider);
    final inGameIds = session == null
        ? <String>{}
        : session.players.where((p) => p.role != null).map((p) => p.role!.id).toSet();

    final roles = RoleGlossary.all.where(_matches).toList();
    final inGame = roles.where((r) => inGameIds.contains(r.id)).toList();
    final wolves = roles.where((r) => r.team == RoleTeam.werewolf).toList();
    final villagers = roles.where((r) => r.team == RoleTeam.villager).toList();
    final others = roles.where((r) => r.team == RoleTeam.neutral).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.bookOpen, color: AppTheme.highlight, size: 20),
                    const SizedBox(width: 8),
                    Text('Thẻ Vai (${RoleGlossary.all.length})', style: AppTheme.cinzelDisplay(18)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(PhosphorIconsFill.x, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: AppTheme.nunitoBody(14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Tìm vai theo tên hoặc kỹ năng...',
                    hintStyle: AppTheme.nunitoBody(13, color: AppTheme.textSecondary),
                    prefixIcon:
                        Icon(PhosphorIconsFill.magnifyingGlass, color: AppTheme.highlight, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(PhosphorIconsFill.x, size: 18, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppTheme.outline),
              Expanded(
                child: roles.isEmpty
                    ? Center(
                        child: Text('Không tìm thấy vai nào.',
                            style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                      )
                    : ListView(
                        controller: ctrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (inGame.isNotEmpty) ...[
                            _label('🎮 Trong ván này (${inGame.length})'),
                            ...inGame.map((r) => _tile(r, inGame: true)),
                            const SizedBox(height: 12),
                          ],
                          if (wolves.isNotEmpty) ...[
                            _label('Phe Ma Sói (${wolves.length})'),
                            ...wolves.map((r) => _tile(r)),
                            const SizedBox(height: 12),
                          ],
                          if (villagers.isNotEmpty) ...[
                            _label('Phe Dân Làng (${villagers.length})'),
                            ...villagers.map((r) => _tile(r)),
                            const SizedBox(height: 12),
                          ],
                          if (others.isNotEmpty) ...[
                            _label('Phe khác / Mở rộng (${others.length})'),
                            ...others.map((r) => _tile(r)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _teamColor(RoleTeam team) {
    switch (team) {
      case RoleTeam.werewolf:
        return AppTheme.danger;
      case RoleTeam.neutral:
        return AppTheme.textSecondary;
      case RoleTeam.villager:
        return AppTheme.highlight;
    }
  }

  String _teamLabel(RoleTeam team) {
    switch (team) {
      case RoleTeam.werewolf:
        return 'Sói';
      case RoleTeam.neutral:
        return 'Khác';
      case RoleTeam.villager:
        return 'Dân';
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTheme.nunitoBody(12, color: AppTheme.textSecondary)),
      );

  Widget _tile(GlossaryRole r, {bool inGame = false}) {
    final color = _teamColor(r.team);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inGame ? AppTheme.highlight : AppTheme.outline, width: inGame ? 1.5 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(RoleIcons.iconFor(r.id, r.team), color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(r.nameVi, style: AppTheme.cinzelDisplay(15))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_teamLabel(r.team),
                          style: AppTheme.nunitoBody(11, color: color)),
                    ),
                  ],
                ),
                Text(r.nameEn, style: AppTheme.nunitoBody(11, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(r.description, style: AppTheme.nunitoBody(13, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
