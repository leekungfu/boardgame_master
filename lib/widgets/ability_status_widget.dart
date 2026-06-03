import 'package:flutter/material.dart';
import '../models/ability_state.dart';
import '../theme/app_theme.dart';

class AbilityStatusWidget extends StatelessWidget {
  final AbilityState abilityState;

  const AbilityStatusWidget({super.key, required this.abilityState});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(label: '🧪 Bình cứu', used: abilityState.witchSaveUsed),
        const SizedBox(width: 8),
        _Pill(label: '☠️ Bình độc', used: abilityState.witchKillUsed),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool used;

  const _Pill({required this.label, required this.used});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: used ? Colors.white10 : AppTheme.accentGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: used ? Colors.white24 : AppTheme.accentGreen.withOpacity(0.5),
        ),
      ),
      child: Text(
        '$label: ${used ? "đã dùng" : "còn"}',
        style: AppTheme.nunitoBody(12, color: used ? AppTheme.textSecondary : AppTheme.accentGreen),
      ),
    );
  }
}
