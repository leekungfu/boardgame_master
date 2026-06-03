import 'package:flutter/material.dart';
import '../models/role.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../theme/role_icons.dart';

class RoleCardWidget extends StatelessWidget {
  final Role role;
  final bool compact;
  final bool selected;
  final VoidCallback? onTap;

  const RoleCardWidget({
    super.key,
    required this.role,
    this.compact = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forRole(role.id);
    final accent = AppGradients.accentForRole(role.id);
    return compact ? _buildCompact(gradient, accent) : _buildFull(gradient, accent);
  }

  Widget _buildFull(LinearGradient gradient, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(selected ? 0.9 : 0.4), width: selected ? 2 : 1),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 12, spreadRadius: 1)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(RoleIcons.iconFor(role.id, role.team), color: accent, size: 40),
            const SizedBox(height: 8),
            Text(role.name, style: AppTheme.cinzelDisplay(18, color: accent)),
            const SizedBox(height: 4),
            Text(role.description, style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(LinearGradient gradient, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(selected ? 0.9 : 0.35), width: selected ? 2 : 1),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(RoleIcons.iconFor(role.id, role.team), color: accent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name, style: AppTheme.cinzelDisplay(14, color: accent)),
                  const SizedBox(height: 2),
                  Text(role.description,
                      style: AppTheme.nunitoBody(11, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
