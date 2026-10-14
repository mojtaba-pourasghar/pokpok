// The real app on a device or emulator (real Hive storage, real audio, real fonts):
//   flutter test integration_test/app_test.dart -d <device>
// The same flows run headless in test/app_flow_test.dart; this file checks them on hardware.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:popo/main.dart' as app;

Future<void> frames(WidgetTester tester, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start → map → home → toggle the lamp → back to the map', (tester) async {
    await app.main();
    await frames(tester, 40);
    await tester.tap(find.text('شروع بازی'));
    await frames(tester);
    if (find.text('رد کردن').evaluate().isNotEmpty) {
      await tester.tap(find.text('رد کردن'));
      await frames(tester);
    }
    expect(find.text('خانه‌ی من'), findsOneWidget);
    await tester.tap(find.text('خانه‌ی من'));
    await frames(tester, 30);
    expect(find.textContaining('پذیرایی'), findsWidgets);
    final semantics = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('چراغ'));
    await frames(tester, 10);
    semantics.dispose();
    await tester.tap(find.byTooltip('بازگشت'));
    await frames(tester);
    expect(find.text('خانه‌ی من'), findsOneWidget);
  });
}
