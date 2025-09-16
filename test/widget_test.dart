// This is a generated file; do not edit or check into version control.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kafe_pos/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KafePosApp());

    // Verify that our cafe app loads properly
    expect(find.text('Kafe POS'), findsOneWidget);
    expect(find.text('Masa Seçimi'), findsOneWidget);
  });
}