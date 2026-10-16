import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niyosense_mobile/main.dart';

void main() {
  testWidgets('NiyoSense App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NiyoSenseApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the app builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
