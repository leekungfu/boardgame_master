import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onFinished;
  final bool autoStart;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onFinished,
    this.autoStart = true,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulse = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.autoStart) _start();
  }

  @override
  void didUpdateWidget(CountdownTimer old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      _timer?.cancel();
      _pulseCtrl.stop();
      _remaining = widget.seconds;
      _running = false;
      if (widget.autoStart) _start();
    }
  }

  void _start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        setState(() => _running = false);
        widget.onFinished?.call();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 5 && !_pulseCtrl.isAnimating) {
        _pulseCtrl.repeat(reverse: true);
      }
    });
    setState(() {});
  }

  void _pause() { _timer?.cancel(); _pulseCtrl.stop(); setState(() => _running = false); }
  void _reset() {
    _timer?.cancel();
    _pulseCtrl.stop();
    setState(() { _remaining = widget.seconds; _running = false; });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _arcColor {
    final fraction = _remaining / widget.seconds;
    if (fraction > 0.5) return AppTheme.accentGreen;
    if (fraction > 0.25) return AppTheme.hunterAmber;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _arcColor;
    final progress = 1.0 - (_remaining / widget.seconds);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _remaining <= 5 ? _pulse.value : 1.0,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _ArcPainter(progress: progress, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_remaining', style: AppTheme.cinzelDisplay(28, color: color)),
                    Text('giây', style: AppTheme.nunitoBody(11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_running ? PhosphorIconsFill.pauseCircle : PhosphorIconsFill.playCircle),
                color: color,
                iconSize: 32,
                onPressed: _running ? _pause : _start,
              ),
              IconButton(
                icon: const Icon(PhosphorIconsFill.arrowClockwise),
                color: AppTheme.textSecondary,
                iconSize: 26,
                onPressed: _reset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(center, radius,
        Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 6);

    final remaining = 1 - progress;
    if (remaining > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * remaining,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = progress > 0.75 ? const MaskFilter.blur(BlurStyle.normal, 3) : null,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress || old.color != color;
}
