import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biyer_bazar/main.dart';

void main() {
  testWidgets('BiyerBajar app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BiyerBajarApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
