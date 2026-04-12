import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_game/main.dart';

void main() {
  testWidgets('ホーム画面が表示されるスモークテスト', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MemoryGameApp()),
    );
    expect(find.text('Memory Game'), findsOneWidget);
    expect(find.text('スタート'), findsOneWidget);
  });
}
