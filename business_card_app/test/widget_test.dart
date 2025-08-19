// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/main.dart';

void main() {
  testWidgets('Business Card App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: BusinessCardApp()),
    );
    
    // Wait for localization to load
    await tester.pumpAndSettle();

    // Verify that our app loads correctly.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Business Card'), findsOneWidget);
    
    // Test language button exists
    expect(find.byIcon(Icons.language), findsOneWidget);
  });
}
