import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../games/game_registry.dart';
import '../games/base_game.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/atmospheric_background.dart';
import '../widgets/theme_toggle_button.dart';
import 'setup/player_setup_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // rebuild palette instantly on light/dark toggle
    final games = GameRegistry.all;

    return Scaffold(
      body: AtmosphericBackground(
        isNight: true,
        child: SafeArea(
          child: Stack(
            children: [
              // Watermark wolf
              Positioned(
                bottom: 40,
                right: -20,
                child: Text('🐺',
                    style: TextStyle(fontSize: 180, color: AppTheme.textPrimary.withOpacity(0.03))),
              ),
              // Light/dark theme toggle
              const Positioned(
                top: 8,
                right: 8,
                child: ThemeToggleButton(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🎮', style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Board Game\nMaster', style: AppTheme.cinzelDisplay(32, color: AppTheme.accent)),
                            const SizedBox(height: 8),
                            Text('Chọn game để bắt đầu', style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.separated(
                        itemCount: games.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) => FadeTransition(
                          opacity: _fade,
                          child: _GameCard(
                            game: games[i],
                            onTap: () {
                              ref.read(setupProvider.notifier).selectGame(games[i]);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerSetupScreen()));
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final BaseGame game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard(borderColor: AppTheme.accent.withOpacity(0.4)),
        child: Row(
          children: [
            Text(game.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name, style: AppTheme.cinzelDisplay(18)),
                  const SizedBox(height: 4),
                  Text(game.description, style: AppTheme.nunitoBody(13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '${game.minPlayers}–${game.maxPlayers} người chơi',
                    style: AppTheme.nunitoBody(12, color: AppTheme.accent),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsFill.caretRight, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
