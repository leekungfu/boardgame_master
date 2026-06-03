import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Standard Werewolf rules shown at game start (with a Skip button) and
/// re-openable from the game screen. Keeps the QT aligned on the exact rules —
/// especially the day-vote majority rule — to avoid mistakes mid-game.
class GameRulesSheet extends StatelessWidget {
  /// When true, shows "Bỏ qua" + "Bắt đầu" actions (start-of-game mode).
  /// When false, shows a single "Đóng" action (reference mode).
  final bool atGameStart;

  const GameRulesSheet({super.key, this.atGameStart = false});

  static Future<void> show(BuildContext context, {bool atGameStart = false}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !atGameStart,
      enableDrag: !atGameStart,
      backgroundColor: Colors.transparent,
      builder: (_) => GameRulesSheet(atGameStart: atGameStart),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.gavel, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Luật chơi Ma Sói', style: AppTheme.cinzelDisplay(18)),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _section('🎯 Mục tiêu', [
                    'Phe Dân Làng: tìm và loại hết Ma Sói.',
                    'Phe Ma Sói: giết dần dân làng cho tới khi số Sói ≥ số Dân.',
                  ]),
                  _section('🌙 Ban đêm', [
                    'Tất cả nhắm mắt. QT lần lượt gọi từng vai dậy theo thứ tự.',
                    '🛡️ Hiệp Sĩ chọn 1 người để bảo vệ (không lặp lại người đêm trước).',
                    '🐺 Ma Sói thống nhất cắn 1 người.',
                    '🔮 Tiên Tri soi 1 người để biết Sói hay Dân.',
                    '🧪 Phù Thủy biết ai bị Sói cắn, có thể dùng bình cứu và/hoặc bình độc (mỗi loại 1 lần cả ván).',
                  ]),
                  _section('🌅 Buổi sáng', [
                    'App tự tính ai chết: nạn nhân của Sói chết, TRỪ KHI được Hiệp Sĩ bảo vệ hoặc Phù Thủy cứu.',
                    'Người bị Phù Thủy đầu độc luôn chết (không cản được).',
                    'QT chỉ cần đọc thông báo — không phải tự tích người chết.',
                  ]),
                  _voteSection(),
                  _section('🏹 Vai đặc biệt khi chết', [
                    'Thợ Săn: khi chết (bất kỳ lý do) được bắn chết thêm 1 người.',
                    'Thằng Ngốc: lần đầu bị treo cổ sẽ lộ bài nhưng KHÔNG chết.',
                  ]),
                  _section('🏆 Điều kiện thắng', [
                    'Dân thắng khi tất cả Ma Sói bị loại.',
                    'Sói thắng khi số Sói ≥ số Dân còn sống.',
                    'App tự kiểm tra điều kiện thắng sau mỗi cái chết.',
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: atGameStart
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
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
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
                              },
                              child: const Text('Đã hiểu, bắt đầu →'),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.checkSquare, size: 18, color: AppTheme.accentRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text('☀️ Bỏ phiếu ban ngày (QUAN TRỌNG)',
                    style: AppTheme.cinzelDisplay(14, color: AppTheme.accentRed)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._bullets([
            'Cả làng thảo luận rồi đề cử những người bị nghi (chọn thoải mái nhiều người).',
            'Vote treo cổ: mỗi người sống bỏ tối đa 1 phiếu "chết" cho 1 ứng viên.',
            'Ai KHÔNG vote được tính là phiếu "sống".',
            'Một người chỉ bị treo cổ khi phiếu chết QUÁ BÁN số người còn sống (> 1/2).',
            'Ví dụ: 7 người sống → cần ≥ 4 phiếu; 8 người sống → cần ≥ 5 phiếu.',
            'Nếu không ai đủ quá bán → KHÔNG ai bị treo cổ hôm đó.',
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.cinzelDisplay(15, color: AppTheme.accent)),
          const SizedBox(height: 6),
          ..._bullets(bullets),
        ],
      ),
    );
  }

  List<Widget> _bullets(List<String> items) {
    return items
        .map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 5, left: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: AppTheme.nunitoBody(14, color: AppTheme.textSecondary)),
                  Expanded(
                    child: Text(t,
                        style: AppTheme.nunitoBody(13, color: AppTheme.textPrimary)
                            .copyWith(height: 1.5)),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
