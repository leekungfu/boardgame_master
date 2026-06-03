import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerStatusChip extends StatefulWidget {
  final String name;
  final int seatNumber;
  final bool isAlive;
  final String? roleEmoji;
  final Color? borderColor;
  final VoidCallback? onTap;

  const PlayerStatusChip({
    super.key,
    required this.name,
    required this.seatNumber,
    this.isAlive = true,
    this.roleEmoji,
    this.borderColor,
    this.onTap,
  });

  @override
  State<PlayerStatusChip> createState() => _PlayerStatusChipState();
}

class _PlayerStatusChipState extends State<PlayerStatusChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _wasDead = false;

  @override
  void initState() {
    super.initState();
    _wasDead = !widget.isAlive;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.2, curve: Curves.easeIn)),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
  }

  @override
  void didUpdateWidget(PlayerStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_wasDead && !widget.isAlive) {
      _controller.forward(from: 0);
      _wasDead = true;
    } else if (widget.isAlive) {
      _controller.reset();
      _wasDead = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderCol = widget.borderColor ?? AppTheme.accent;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.scale(
            scale: widget.isAlive ? 1.0 : _scale.value,
            child: child,
          );
        },
        child: ColorFiltered(
          colorFilter: widget.isAlive
              ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
              : const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.nightCardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isAlive ? borderCol.withOpacity(0.7) : Colors.white12,
                width: widget.isAlive ? 1.5 : 1,
              ),
              boxShadow: widget.isAlive
                  ? [BoxShadow(color: borderCol.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: borderCol.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.seatNumber}',
                        style: AppTheme.cinzelDisplay(11, color: widget.isAlive ? borderCol : AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.name,
                      style: AppTheme.nunitoBody(14,
                          color: widget.isAlive ? AppTheme.textPrimary : AppTheme.textSecondary).copyWith(
                        decoration: widget.isAlive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (widget.roleEmoji != null) ...[
                      const SizedBox(width: 6),
                      Text(widget.roleEmoji!, style: const TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
                if (!widget.isAlive)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: FadeTransition(
                      opacity: _opacity,
                      child: const Text('💀', style: TextStyle(fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
