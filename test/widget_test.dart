import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:statline/app.dart';

void main() {
  testWidgets('StatLine app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StatLineApp()),
    );
    await tester.pumpAndSettle();

    // Verify the app renders with the Dashboard tab
    expect(find.text('StatLine'), findsOneWidget);
  });
}
