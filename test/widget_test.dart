import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boardgame_master/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app starts on home screen with Ma Soi game card', (tester) async {
    // BoardGameMasterApp is a ConsumerWidget (watches the theme provider), so it
    // must be hosted under a ProviderScope.
    await tester.pumpWidget(const ProviderScope(child: BoardGameMasterApp()));
    await tester.pump();
    expect(find.text('Ma Sói'), findsWidgets);
  });

}
