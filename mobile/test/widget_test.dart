import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vibra9/main.dart";

void main() {
  testWidgets("Vibra9 app initializes without crashing",
      (WidgetTester tester) async {
    await tester.pumpWidget(const Vibra9App());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
