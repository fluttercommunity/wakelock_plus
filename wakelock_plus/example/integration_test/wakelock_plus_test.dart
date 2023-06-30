import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('enabling and disabling wakelock', (WidgetTester tester) async {
    final wakelockEnabled = await WakelockPlus.enabled;

    // The wakelock should initially be disabled.
    expect(wakelockEnabled, isFalse);

    await WakelockPlus.enable();
    expect(await WakelockPlus.enabled, isTrue);
    await WakelockPlus.disable();
    expect(await WakelockPlus.enabled, isFalse);
  });

  testWidgets('toggling wakelock', (WidgetTester tester) async {
    await WakelockPlus.toggle(enable: true);
    expect(await WakelockPlus.enabled, isTrue);
    await WakelockPlus.toggle(enable: false);
    expect(await WakelockPlus.enabled, isFalse);
  });
}
