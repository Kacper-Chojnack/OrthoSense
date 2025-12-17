import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/main.dart';

void main() {
  testWidgets('OrthoSense app renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: OrthoSenseApp()),
    );

    expect(
      find.text('OrthoSense - Phase 1: Foundation Complete'),
      findsOneWidget,
    );
  });
}
