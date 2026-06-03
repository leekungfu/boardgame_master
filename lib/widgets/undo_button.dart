import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

/// Shared undo control. Reverts the most recent reversible action at any phase.
///
/// Watches [gameProvider] so it re-evaluates `canUndo` on every state change,
/// disabling itself when there is nothing left to undo in the current session.
///
/// - [compact] renders an icon-only button (for dense app bars).
/// - otherwise renders a labelled outlined button (for action rows).
class UndoButton extends ConsumerWidget {
  final bool compact;
  final String label;
  final VisualDensity? visualDensity;

  const UndoButton({
    super.key,
    this.compact = false,
    this.label = 'Hoàn tác',
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild whenever game state changes (every reversible action also
    // mutates the session, so canUndo stays in sync).
    ref.watch(gameProvider);
    final canUndo = ref.read(gameProvider.notifier).canUndo;

    void onUndo() {
      HapticFeedback.mediumImpact();
      ref.read(gameProvider.notifier).undo();
    }

    if (compact) {
      return IconButton(
        icon: const Icon(PhosphorIconsFill.arrowUUpLeft, size: 20),
        tooltip: label,
        visualDensity: visualDensity,
        onPressed: canUndo ? onUndo : null,
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(PhosphorIconsFill.arrowUUpLeft, size: 18),
      label: Text(label),
      onPressed: canUndo ? onUndo : null,
    );
  }
}
